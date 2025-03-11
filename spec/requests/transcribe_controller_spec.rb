require 'spec_helper'

describe TranscribeController do
  before do
    User.current_user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  describe '#display_page' do
    let(:action_path) { collection_transcribe_page_path(owner, collection, work, page) }
    let(:subject) { get action_path }

    context 'when user is not logged in' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when read-only document set and user is not a collaborator' do
      let!(:document_set) { create(:document_set, :read_only, owner_user_id: owner.id, collection_id: collection.id) }
      let!(:user) { create(:unique_user) }
      let(:action_path) { collection_transcribe_page_path(owner, document_set, work, page) }

      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_display_page_path(owner, document_set, work, page))
      end
    end

    context 'when collection is field_based' do
      context 'when with field cells' do
        let!(:collection) { create(:collection, owner_user_id: owner.id, field_based: true) }
        let!(:text_field) do
          create(:transcription_field, :as_transcription, collection: collection, label: 'Text Field', input_type: 'text')
        end
        let!(:select_field) do
          create(:transcription_field, :as_transcription, collection: collection, label: 'Select Field',
                                                          input_type: 'select', options: 'one;two;three;')
        end
        let!(:date_field) do
          create(:transcription_field, :as_transcription, collection: collection, label: 'Select Field',
                                                          input_type: 'date')
        end
        let!(:text_area_field) do
          create(:transcription_field, :as_transcription, collection: collection, label: 'Select Field',
                                                          input_type: 'textarea')
        end
        let!(:description_field) do
          create(:transcription_field, :as_transcription, collection: collection, label: 'Description Field',
                                                          input_type: 'description')
        end
        let!(:instruction_field) do
          create(:transcription_field, :as_transcription, collection: collection, label: 'Description Field',
                                                          input_type: 'instruction')
        end
        let!(:spreadsheet_field) do
          create(:transcription_field, :as_transcription, collection: collection, label: 'Spreadsheet Field',
                                                          input_type: 'spreadsheet')
        end
        let!(:text_column) do
          create(:spreadsheet_column, transcription_field: spreadsheet_field, label: 'Text Column', input_type: 'text')
        end
        let!(:numeric_column) do
          create(:spreadsheet_column, transcription_field: spreadsheet_field, label: 'Numeric Column',
                                      input_type: 'numeric')
        end
        let!(:select_column) do
          create(:spreadsheet_column, transcription_field: spreadsheet_field, label: 'Select Column',
                                      options: 'one;two;three;', input_type: 'select')
        end
        let!(:checkbox_column) do
          create(:spreadsheet_column, transcription_field: spreadsheet_field, label: 'Checkbox Column',
                                      input_type: 'checkbox')
        end
        let!(:date) do
          create(:spreadsheet_column, transcription_field: spreadsheet_field, label: 'Date Column',
                                      input_type: 'date')
        end

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:display_page)
        end

        context 'when old table_cells system' do
          before do
            page.update_column(:transcription_json, nil)
          end

          let!(:text_field_cell) do
            create(:table_cell, work: work, page: page, transcription_field: text_field)
          end
          let!(:spreadsheet_column_cell) do
            create(:table_cell, work: work, page: page, transcription_field: spreadsheet_field, header: 'Text Column')
          end

          it 'renders status and template' do
            login_as owner
            subject

            expect(response).to have_http_status(:ok)
            expect(response).to render_template(:display_page)
          end
        end

        context 'when without field cells' do
          before do
            page.update_column(:transcription_json, nil)
          end

          it 'renders status and template' do
            login_as owner
            subject

            expect(response).to have_http_status(:ok)
            expect(response).to render_template(:display_page)
          end
        end
      end
    end

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:display_page)
    end
  end
end
