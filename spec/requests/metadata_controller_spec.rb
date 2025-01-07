require 'spec_helper'

describe MetadataController do
  before do
    User.current_user = owner
  end

  let(:owner) { User.find_by(login: OWNER) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:original_metadata) { [{ label: 'Label', value: 'Value' }].to_json }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id, original_metadata: original_metadata) }

  describe '#example' do
    let(:action_path) { collection_metadata_example_path(collection_id: collection.id) }
    let(:subject) { get action_path }

    it 'renders status' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
    end
  end

  describe '#upload' do
    let(:action_path) { collection_metadata_upload_path(collection.id) }
    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:upload)
    end
  end

  describe '#create' do
    let(:action_path) { collection_metadata_create_path }
    let(:file) do
      result = Work::Metadata::ExportCsv.call(collection: collection, works: Work.where(id: work.id))
      temp_file = Tempfile.new(['metadata', '.csv'])
      temp_file.write(result.csv_string)
      temp_file.rewind
      Rack::Test::UploadedFile.new(temp_file.path, 'text/csv')
    end
    let(:params) do
      {
        metadata: {
          file: file,
          collection_id: collection.id
        }
      }
    end
    let(:subject) { post action_path, params: params }

    it 'redirects' do
      login_as owner
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(edit_look_collection_path(owner, collection))
    end
  end

  describe '#refresh' do
    let(:action_path) { collection_metadata_refresh_path(collection.id) }
    let(:subject) { post action_path }

    it 'redirects' do
      login_as owner
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(edit_look_collection_path(owner, collection))
    end
  end
end
