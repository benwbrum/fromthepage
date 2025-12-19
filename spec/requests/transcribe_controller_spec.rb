require 'spec_helper'

describe TranscribeController do
  before do
    Current.user = owner
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

    context 'when collection is inactive' do
      let!(:user) { create(:unique_user) }

      before do
        collection.update!(is_active: false)
      end

      it 'redirects to collection overview instead of display page' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(collection_path(owner, collection))
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
        let!(:alt_text_field) do
          create(:transcription_field, :as_transcription, collection: collection, label: 'Alt Text Field',
                                                          input_type: 'alt text')
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

          context 'with broken tag' do
            let!(:text_field_cell) do
              create(:table_cell, work: work, page: page, transcription_field: text_field, content: '<Broken tag')
            end
            let!(:spreadsheet_column_cell) do
              create(:table_cell, work: work, page: page, transcription_field: spreadsheet_field, header: 'Text Column', content: '<Broken tag')
            end

            it 'renders status and template' do
              login_as owner
              subject

              expect(response).to have_http_status(:ok)
              expect(response).to render_template(:display_page)
            end
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

  describe '#save_transcription' do
    # TODO: Move logic to interactor for better isolation testing
    # Temporary, do not do this pattern for request tests
    context 'Article rename race check' do
      # Scenario:
      # Article is renamed and rename job is still running.
      # Another user made update to current page
      # while rename job is unfinished
      let!(:page) { create(:page, work: work, source_text: '[[Original]]', source_translation: '[[Original]]') }
      let!(:category) { create(:category) }
      let!(:article) do
        create(:article, title: 'Original', collection: collection, pages: [page], categories: [category])
      end
      let!(:source_article) do
        create(:article, collection: collection.reload)
      end
      let!(:article_article_link) do
        create(:article_article_link, source_article: source_article, target_article: article)
      end

      let(:action_path) do
        collection_oneoff_review_page_save_path(
          user_slug: owner.slug,
          collection_id: collection.slug,
          page_id: page.id
        )
      end

      let(:params) do
        {
          flow: '',
          quality_sampling_id: '',
          page: {
            mark_blank: '0',
            needs_review: '0',
            source_text: '[[Original]] some change'
          },
          save_to_transcribed: '',
          'filter-brightness' => '0',
          'filter-contrast' => '0',
          'filter-threshold' => '0'
        }
      end

      let(:subject) { patch action_path, params: params }

      it 'updates page without losing article links' do
        source_article.update_column(:source_text, '[[Original]]')
        article.update!(title: 'Renamed')

        login_as owner
        subject

        expect(page.reload.source_text).to include('[[Original]] some change')
        expect(page.articles.reload).to include(article)
        expect(article.reload.categories).to include(category)
      end
    end
  end

  describe '#help' do
    let(:action_path) { collection_help_page_path(owner, collection, work, page) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:help)
    end
  end

  describe '#mark_page_blank' do
    let(:action_path) { transcribe_mark_page_blank_path(page_id: page.id) }

    let(:subject) { post action_path, as: :turbo_stream }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:mark_page_blank)
    end
  end

  # TODO: Full test suite for save_transcription
  # For now, we cover the branch for mark_blank logic
  describe '#save_transcription' do
    let(:action_path) { transcribe_save_transcription_path }
    let(:params) { {} }

    let(:subject) { patch action_path, params: params }

    context 'mark_blank_logic' do
      let!(:search_attempt) do
        create(:search_attempt, user_id: owner.id, search_type: 'findaproject', query: page.title)
      end
      let(:params) do
        {
          page_id: page.id,
          page: {
            mark_blank: '1'
          }
        }
      end

      before do
        allow(Current).to receive(:session).and_return({ search_attempt_id: search_attempt.id })
      end

      context 'when non-blank page is set to blank and there is next page' do
        let!(:next_page) { create(:page, work: work) }

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_transcribe_page_path(collection.owner, collection, page.work, next_page.id)
          )
        end
      end

      context 'when last non-blank page is set to blank' do
        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_transcribe_page_path(collection.owner, collection, page.work, page.id)
          )
        end
      end

      context 'when last blank page was set to blank again' do
        let!(:page) { create(:page, work: work, status: :blank, translation_status: :blank) }

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_transcribe_page_path(collection.owner, collection, page.work, page.id)
          )
        end
      end

      context 'when last non-blank page was set to not blank again' do
        let(:params) do
          {
            page_id: page.id,
            page: {
              mark_blank: '0'
            }
          }
        end

        it 'renders status' do
          login_as owner
          subject

          # This branch will go through the rest of the save_transcription logic
          # TODO: Add tests for said branch
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when last blank page was set to not blank' do
        let!(:page) { create(:page, work: work, status: :blank, translation_status: :blank) }

        let(:params) do
          {
            page_id: page.id,
            page: {
              mark_blank: '0'
            }
          }
        end

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_transcribe_page_path(collection.owner, collection, page.work, page.id)
          )
        end
      end

      context 'when needs_review == 1' do
        let(:params) do
          {
            page_id: page.id,
            page: {
              mark_blank: '0',
              needs_review: '1'
            }
          }
        end

        it 'renders status' do
          login_as owner
          subject

          # This branch will go through the rest of the needs_review logic
          # TODO: Add tests for said branch
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'preview logic' do
      let(:source_text) { 'Hello world' }
      let(:params) do
        {
          page_id: page.id,
          preview: '1',
          page: {
            source_text: source_text
          }
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:display_page)
      end

      context 'when previewing subjects' do
        let(:source_text) { '[[Hello]] world' }

        it 'renders status and template and does not create articles' do
          articles_count = collection.articles.count
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:display_page)

          expect(articles_count).to eq(collection.reload.articles.count)
        end
      end

      context 'with transcription errors' do
        let(:source_text) { '<hi rend="bold">Unclosed' }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:display_page)
        end
      end
    end
  end

  # TODO: Full test suite for save_translation
  # For now, we cover the branch for mark_blank logic
  describe '#save_translation' do
    let(:action_path) { transcribe_save_translation_path }
    let(:params) { {} }

    let(:subject) { patch action_path, params: params }

    context 'mark_blank_logic' do
      let!(:search_attempt) do
        create(:search_attempt, user_id: owner.id, search_type: 'findaproject', query: page.title)
      end
      let(:params) do
        {
          page_id: page.id,
          page: {
            mark_blank: '1'
          }
        }
      end

      before do
        allow(Current).to receive(:session).and_return({ search_attempt_id: search_attempt.id })
      end

      context 'when non-blank page is set to blank' do
        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_display_page_path(collection.owner, collection, page.work, page.id)
          )
        end
      end

      context 'when blank page was set to blank again' do
        let!(:page) { create(:page, work: work, status: :blank, translation_status: :blank) }

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_display_page_path(collection.owner, collection, page.work, page.id)
          )
        end
      end

      context 'when non-blank page was set to not blank again' do
        let(:params) do
          {
            page_id: page.id,
            page: {
              mark_blank: '0'
            }
          }
        end

        it 'renders status' do
          login_as owner
          subject

          # This branch will go through the rest of the save_transcription logic
          # TODO: Add tests for said branch
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when blank page was set to not blank' do
        let!(:page) { create(:page, work: work, status: :blank, translation_status: :blank) }

        let(:params) do
          {
            page_id: page.id,
            page: {
              mark_blank: '0'
            }
          }
        end

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(
            collection_display_page_path(collection.owner, collection, page.work, page.id)
          )
        end
      end

      context 'when needs_review == 1' do
        let(:params) do
          {
            page_id: page.id,
            page: {
              mark_blank: '0',
              needs_review: '1'
            }
          }
        end

        it 'renders status' do
          login_as owner
          subject

          # This branch will go through the rest of the needs_review logic
          # TODO: Add tests for said branch
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context 'preview logic' do
      let(:source_translation) { 'Hello world' }
      let(:params) do
        {
          page_id: page.id,
          preview: '1',
          page: {
            source_translation: source_translation
          }
        }
      end

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:translate)
      end

      context 'when previewing subjects' do
        let(:source_translation) { '[[Hello]] world' }

        it 'renders status and template and does not create articles' do
          articles_count = collection.articles.count
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:translate)

          expect(articles_count).to eq(collection.reload.articles.count)
        end
      end

      context 'with transcription errors' do
        let(:source_translation) { '<hi rend="bold">Unclosed' }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:translate)
        end
      end
    end
  end
end
