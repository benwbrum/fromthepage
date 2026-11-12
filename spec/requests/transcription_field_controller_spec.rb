require 'spec_helper'

# SEC-02: every TranscriptionFieldController action requires the collection owner (or an
# admin). Every request carries collection_id and fields are looked up through @collection,
# so ids from another collection can't be used. Mutations no longer go over GET.
describe TranscriptionFieldController do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  # A work makes the collection viewable (Collection#show_to? requires works), so denied
  # signed-in users land on the collection page and authorize_collection lets anonymous
  # requests reach the controller.
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work, base_height: 1000, base_width: 800) }
  let!(:field) { create(:transcription_field, :as_transcription, collection_id: collection.id, label: 'Original') }
  let!(:spreadsheet_field) do
    create(:transcription_field, :as_transcription, :spreadsheet_field,
           collection_id: collection.id, label: 'Sheet', top_offset: 0.0, bottom_offset: 0.0)
  end
  let!(:metadata_field) do
    create(:transcription_field, :as_metadata, collection_id: collection.id, label: 'Meta', input_type: 'multiselect')
  end
  let!(:column) { create(:spreadsheet_column, transcription_field_id: spreadsheet_field.id, label: 'Column', position: 1) }

  let!(:co_owner) { create(:unique_user, :owner).tap { |user| collection.owners << user } }
  let!(:stranger) { create(:unique_user) }
  let!(:admin) { create(:unique_user, :admin) }

  # A second collection owned by someone else, for the cross-collection (IDOR) cases.
  let!(:other_owner) { create(:unique_user, :owner) }
  let!(:other_collection) { create(:collection, owner_user_id: other_owner.id) }
  let!(:other_work) { create(:work, collection: other_collection, owner_user_id: other_owner.id) }
  let!(:other_page) { create(:page, work: other_work, base_height: 1000) }

  def expect_denied_signed_out
    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(dashboard_path)
  end

  def expect_denied_signed_in
    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(collection_path(owner, collection))
    expect(flash[:error]).to eq(I18n.t('permission_denied'))
  end

  describe 'DELETE delete' do
    let(:params) { { field_id: field.id, collection_id: collection.slug } }
    let(:subject) { delete transcription_field_delete_path, params: params }

    it 'denies a signed-out user and keeps the field' do
      subject

      expect_denied_signed_out
      expect(TranscriptionField.exists?(field.id)).to be(true)
    end

    it 'denies a signed-in non-owner and keeps the field' do
      login_as stranger
      subject

      expect_denied_signed_in
      expect(TranscriptionField.exists?(field.id)).to be(true)
    end

    it "denies another collection's owner who sends their own collection_id" do
      login_as other_owner
      delete transcription_field_delete_path, params: { field_id: field.id, collection_id: other_collection.slug }

      expect(response).to have_http_status(:redirect)
      expect(TranscriptionField.exists?(field.id)).to be(true)
    end

    it "denies another collection's owner who sends no collection_id" do
      login_as other_owner
      delete transcription_field_delete_path, params: { field_id: field.id }

      expect(response).to have_http_status(:see_other)
      expect(TranscriptionField.exists?(field.id)).to be(true)
    end

    it 'answers JSON with a bare 401 / 403 and keeps the field' do
      delete transcription_field_delete_path, params: params, as: :json
      expect(response).to have_http_status(:unauthorized)

      login_as stranger
      delete transcription_field_delete_path, params: params, as: :json
      expect(response).to have_http_status(:forbidden)

      expect(TranscriptionField.exists?(field.id)).to be(true)
    end

    it 'lets the owner delete the field' do
      login_as owner
      subject

      expect(response).to redirect_to(collection_edit_fields_path(owner, collection))
      expect(TranscriptionField.exists?(field.id)).to be(false)
    end

    it 'lets a co-owner delete the field' do
      login_as co_owner
      subject

      expect(TranscriptionField.exists?(field.id)).to be(false)
    end

    it 'lets an admin who does not own the collection delete the field' do
      login_as admin
      subject

      expect(TranscriptionField.exists?(field.id)).to be(false)
    end

    # The old GET URL now falls through to the catch-all collection#show route
    # (/:user_slug/:id), so it can't trigger the delete (e.g. from an <img src>).
    it 'cannot be triggered over GET' do
      login_as owner
      get '/transcription_field/delete', params: params

      expect(TranscriptionField.exists?(field.id)).to be(true)
    end
  end

  describe 'POST add_fields' do
    let(:other_field) do
      create(:transcription_field, :as_transcription, collection_id: other_collection.id, label: 'Theirs')
    end

    def add_fields(collection_id:, fields:)
      post transcription_field_add_fields_path, params: {
        collection_id: collection_id,
        field_type: TranscriptionField::FieldType::TRANSCRIPTION,
        transcription_fields: fields
      }
    end

    it 'denies a signed-out user' do
      add_fields(collection_id: collection.slug, fields: [{ id: field.id, label: 'Changed', line_number: 1, input_type: 'text' }])

      expect_denied_signed_out
      expect(field.reload.label).to eq('Original')
    end

    it 'denies a signed-in non-owner' do
      login_as stranger
      add_fields(collection_id: collection.slug, fields: [{ id: field.id, label: 'Changed', line_number: 1, input_type: 'text' }])

      expect_denied_signed_in
      expect(field.reload.label).to eq('Original')
    end

    it "doesn't let an owner update another collection's field through their own collection" do
      login_as owner
      add_fields(collection_id: collection.slug, fields: [{ id: other_field.id, label: 'Hijacked', line_number: 1, input_type: 'text' }])

      expect(other_field.reload.label).to eq('Theirs')
    end

    it 'lets the owner update and create fields, ignoring unpermitted attributes' do
      login_as owner
      add_fields(collection_id: collection.slug, fields: [
        { id: field.id, label: 'Changed', line_number: 1, input_type: 'text' },
        { label: 'Brand new', line_number: 2, input_type: 'text', row_highlight: true, collection_id: other_collection.id }
      ])

      expect(field.reload.label).to eq('Changed')
      created = TranscriptionField.find_by(label: 'Brand new', collection_id: collection.id)
      expect(created).to be_present
      expect(created.row_highlight).to be_falsey
      expect(TranscriptionField.where(label: 'Brand new', collection_id: other_collection.id)).to be_empty
    end

    it 'flashes an error and falls back to a text field when a select has no options' do
      login_as owner
      add_fields(collection_id: collection.slug, fields: [{ id: field.id, label: 'Original', line_number: 1, input_type: 'select' }])

      expect(flash[:error]).to eq(I18n.t('transcription_field.add_fields.must_have_options_list'))
      expect(field.reload.input_type).to eq('text')
    end

    it 'updates metadata fields too (they are not in Collection#transcription_fields)' do
      login_as owner
      post transcription_field_add_fields_path, params: {
        collection_id: collection.slug,
        field_type: TranscriptionField::FieldType::METADATA,
        transcription_fields: [{ id: metadata_field.id, label: 'Meta changed', line_number: 1, input_type: 'text' }]
      }

      expect(metadata_field.reload.label).to eq('Meta changed')
    end
  end

  describe 'PATCH reorder' do
    let(:other_field) { create(:transcription_field, :as_transcription, collection_id: other_collection.id, position: 7) }

    it 'answers a signed-out XHR the way ajax_redirect_to always has' do
      patch transcription_field_reorder_path, params: { collection_id: collection.id, field: [field.id], line: 1 }, xhr: true

      expect(response).to have_http_status(:created)
      expect(response.headers['Location']).to end_with(dashboard_path)
    end

    it 'denies a signed-in non-owner XHR' do
      login_as stranger
      patch transcription_field_reorder_path, params: { collection_id: collection.id, field: [field.id], line: 9 }, xhr: true

      expect(response).to have_http_status(:created)
      expect(response.headers['Location']).to end_with(collection_path(owner, collection))
      expect(field.reload.line_number).not_to eq(9)
    end

    it "only reorders the owner's own fields" do
      login_as owner
      patch transcription_field_reorder_path, params: { collection_id: collection.id, field: [other_field.id, field.id], line: 3 }, xhr: true

      expect(response).to have_http_status(:ok)
      expect(other_field.reload.position).to eq(7)
      expect(field.reload.line_number).to eq(3)
    end
  end

  describe 'DELETE delete (metadata field)' do
    it 'lets the owner delete a metadata field' do
      login_as owner
      delete transcription_field_delete_path, params: { field_id: metadata_field.id, collection_id: collection.slug }

      expect(TranscriptionField.exists?(metadata_field.id)).to be(false)
    end
  end

  describe 'POST save_multiselect_options' do
    def save_multiselect(field_id:, collection_id:)
      post transcription_field_save_multiselect_options_path(field_id),
           params: { collection_id: collection_id, options: 'a;b' }
    end

    it 'denies a signed-in non-owner' do
      login_as stranger
      save_multiselect(field_id: metadata_field.id, collection_id: collection.id)

      expect_denied_signed_in
      expect(metadata_field.reload.options).to be_nil
    end

    it 'denies a request with no collection_id' do
      login_as other_owner
      save_multiselect(field_id: metadata_field.id, collection_id: nil)

      expect(response).to have_http_status(:see_other)
      expect(metadata_field.reload.options).to be_nil
    end

    it "doesn't let another collection's owner change the field through their own collection" do
      login_as other_owner
      save_multiselect(field_id: metadata_field.id, collection_id: other_collection.id)

      expect(metadata_field.reload.options).to be_nil
    end

    it 'lets the owner save the options' do
      login_as owner
      save_multiselect(field_id: metadata_field.id, collection_id: collection.id)

      expect(metadata_field.reload.options).to eq('a;b')
    end
  end

  describe 'spreadsheet columns' do
    describe 'DELETE delete' do
      let(:params) { { spreadsheet_column_id: column.id, field_id: spreadsheet_field.id, collection_id: collection.slug } }

      it 'denies a signed-in non-owner' do
        login_as stranger
        delete transcription_field_spreadsheet_column_delete_path, params: params

        expect_denied_signed_in
        expect(SpreadsheetColumn.exists?(column.id)).to be(true)
      end

      it 'does not delete a column through a different field' do
        login_as owner
        delete transcription_field_spreadsheet_column_delete_path,
               params: params.merge(field_id: field.id)

        expect(SpreadsheetColumn.exists?(column.id)).to be(true)
      end

      it 'lets the owner delete the column' do
        login_as owner
        delete transcription_field_spreadsheet_column_delete_path, params: params

        expect(response).to redirect_to(transcription_field_spreadsheet_column_path(spreadsheet_field.id, collection_id: collection))
        expect(SpreadsheetColumn.exists?(column.id)).to be(false)
      end

      it 'cannot be triggered over GET' do
        login_as owner
        begin
          get '/transcription_field/spreadsheet_column/delete', params: params
        rescue ActionController::RoutingError
          # no matching GET route at all is also fine
        end

        expect(SpreadsheetColumn.exists?(column.id)).to be(true)
      end
    end

    describe 'POST add_columns' do
      let(:other_field) { create(:transcription_field, :as_transcription, :spreadsheet_field, collection_id: other_collection.id) }
      let(:other_column) { create(:spreadsheet_column, transcription_field_id: other_field.id, label: 'Theirs') }

      it "doesn't let an owner update another field's column" do
        login_as owner
        post transcription_field_spreadsheet_column_add_columns_path, params: {
          collection_id: collection.id,
          transcription_field_id: spreadsheet_field.id,
          starting_rows: 1,
          spreadsheet_columns: [{ id: other_column.id, label: 'Hijacked', input_type: 'text' }]
        }

        expect(other_column.reload.label).to eq('Theirs')
      end
    end

    describe 'POST add_columns (validation)' do
      it 'flashes an error when starting rows is blank' do
        login_as owner
        post transcription_field_spreadsheet_column_add_columns_path, params: {
          collection_id: collection.id,
          transcription_field_id: spreadsheet_field.id,
          starting_rows: '',
          spreadsheet_columns: [{ id: column.id, label: 'Column', input_type: 'text' }]
        }

        expect(flash[:error]).to eq(I18n.t('transcription_field.add_columns.starting_rows_must_not_be_blank'))
      end
    end

    describe 'PATCH enable_ruler / disable_ruler' do
      it 'denies a signed-in non-owner' do
        login_as stranger
        patch transcription_field_spreadsheet_column_enable_ruler_path(spreadsheet_field, collection_id: collection.slug)

        expect_denied_signed_in
        expect(spreadsheet_field.reload.row_highlight).to be_falsey
      end

      it 'lets the owner toggle the ruler' do
        login_as owner
        patch transcription_field_spreadsheet_column_enable_ruler_path(spreadsheet_field, collection_id: collection.slug)
        expect(spreadsheet_field.reload.row_highlight).to be(true)

        patch transcription_field_spreadsheet_column_disable_ruler_path(spreadsheet_field, collection_id: collection.slug)
        expect(spreadsheet_field.reload.row_highlight).to be(false)
      end

      it 'denies a request with no collection_id' do
        login_as owner
        patch transcription_field_spreadsheet_column_enable_ruler_path(spreadsheet_field)

        expect(response).to have_http_status(:see_other)
        expect(spreadsheet_field.reload.row_highlight).to be_falsey
      end

      it "doesn't let another collection's owner toggle it through their own collection" do
        login_as other_owner
        patch transcription_field_spreadsheet_column_enable_ruler_path(spreadsheet_field, collection_id: other_collection.slug)

        expect(spreadsheet_field.reload.row_highlight).to be_falsey
      end

      it 'cannot be triggered over GET' do
        login_as owner
        begin
          get "/transcription_field/spreadsheet_column/#{spreadsheet_field.id}/enable_ruler", params: { collection_id: collection.slug }
        rescue ActionController::RoutingError
          # no matching GET route at all is also fine
        end

        expect(spreadsheet_field.reload.row_highlight).to be_falsey
      end
    end

    describe 'POST save_offset' do
      it 'rejects a page from another collection' do
        login_as owner
        expect do
          post transcription_field_spreadsheet_column_save_offset_path(spreadsheet_field, other_page),
               params: { collection_id: collection.slug, selector: 'xywh=pixel:0,100,50,200' }
        end.not_to(change { spreadsheet_field.reload.top_offset })
      end

      it 'lets the owner save the offset for a page in the collection' do
        login_as owner
        post transcription_field_spreadsheet_column_save_offset_path(spreadsheet_field, page),
             params: { collection_id: collection.slug, selector: 'xywh=pixel:0,100,50,200' }

        expect(spreadsheet_field.reload.top_offset).to eq(0.1)
      end
    end
  end

  describe 'read-only screens' do
    # choose_offset renders a random page of the collection and does arithmetic with its
    # dimensions. The collection factory adds works whose pages have none, so size them all.
    before { Page.where(work_id: collection.works.select(:id)).update_all(base_height: 1000, base_width: 800) }

    [
      [:edit_fields, -> { collection_edit_fields_path(owner, collection) }],
      [:edit_metadata_fields, -> { collection_edit_metadata_fields_path(owner, collection) }],
      [:multiselect_form, -> { transcription_field_configure_multiselect_options_path(metadata_field.id, collection_id: collection.slug) }],
      [:edit_columns, -> { transcription_field_spreadsheet_column_path(spreadsheet_field.id, collection_id: collection.slug) }],
      [:choose_offset, -> { transcription_field_spreadsheet_column_choose_offset_path(spreadsheet_field.id, collection_id: collection.slug) }]
    ].each do |action, path|
      describe action.to_s do
        it 'denies a signed-in non-owner' do
          login_as stranger
          get instance_exec(&path)

          expect_denied_signed_in
        end

        it 'renders for the owner' do
          login_as owner
          get instance_exec(&path)

          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe 'GET column_form' do
    let(:path) { "/transcription_field/spreadsheet_column/#{spreadsheet_field.id}/column_form" }

    it 'denies a signed-in non-owner XHR' do
      login_as stranger
      get path, params: { collection_id: collection.slug }, xhr: true

      expect(response).to have_http_status(:created)
      expect(response.headers['Location']).to end_with(collection_path(owner, collection))
    end

    it 'renders for the owner' do
      login_as owner
      get path, params: { collection_id: collection.slug }, xhr: true

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET line_form' do
    def line_form(collection_id: collection.slug, line_count: 'Line 1')
      get transcription_field_line_form_path,
          params: { collection_id: collection_id, line_count: line_count, field_type: 'transcription' }, xhr: true
    end

    it 'denies a signed-out XHR' do
      line_form

      expect(response).to have_http_status(:created)
      expect(response.headers['Location']).to end_with(dashboard_path)
    end

    it 'denies a signed-in non-owner XHR' do
      login_as stranger
      line_form

      expect(response).to have_http_status(:created)
      expect(response.headers['Location']).to end_with(collection_path(owner, collection))
    end

    it 'denies a request with no collection_id' do
      login_as owner
      line_form(collection_id: nil)

      expect(response).to have_http_status(:created)
    end

    it 'renders the next line for the owner' do
      login_as owner
      line_form

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Line 2')
    end

    it 'does not raise when line_count is missing' do
      login_as owner
      line_form(line_count: nil)

      expect(response).to have_http_status(:ok)
    end
  end
end
