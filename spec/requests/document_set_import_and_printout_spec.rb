require 'spec_helper'

RSpec.describe 'Document-set imports and configurable printouts', type: :request do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:visitor) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, visibility: :public, user_download: true) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:document_set) { create(:document_set, :public, collection: collection, owner_user_id: owner.id, works: [work]) }
  let(:import_params) do
    { collection_id: "D#{document_set.id}", cdm_urls: "https://example.test/digital/collection/test/id/1\n\nhttps://example.test/digital/collection/test/id/2",
      ocr_correction: '1', generate_ai_draft: '1' }
  end

  before do
    Current.user = owner
    allow_any_instance_of(CdmBulkImport).to receive(:submit_background_task)
  end

  after { Warden.test_reset! }

  it 'imports CONTENTdm into an owned document set' do
    login_as owner
    expect_any_instance_of(CdmBulkImport).to receive(:submit_background_task).once
    expect do
      post sc_collections_cdm_bulk_import_create_path, params: import_params
    end.to change(CdmBulkImport, :count).by(1)
    expect(response).to redirect_to(dashboard_owner_path)
    import = CdmBulkImport.last
    expect(import.collection_or_document_set).to eq(document_set)
    expect(import.user).to eq(owner)
    expect(import.ocr_correction).to be(true)
    expect(import.generate_ai_draft).to be(true)
    expect(import.cdm_urls.lines.size).to eq(2)
  end

  it 'rejects imports into collections and document sets owned by another user' do
    login_as visitor
    expect_any_instance_of(CdmBulkImport).not_to receive(:submit_background_task)
    [collection.id.to_s, "D#{document_set.id}"].each do |selector|
      expect do
        post sc_collections_cdm_bulk_import_create_path, params: import_params.merge(collection_id: selector)
      end.not_to change(CdmBulkImport, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  it 'preserves imports into an owned collection' do
    login_as owner
    post sc_collections_cdm_bulk_import_create_path, params: import_params.merge(collection_id: collection.id)
    expect(response).to redirect_to(dashboard_owner_path)
    expect(CdmBulkImport.last.collection_or_document_set).to eq(collection)
  end

  it 'allows collection staff to import into its document set' do
    collection.owners << visitor
    login_as visitor
    post sc_collections_cdm_bulk_import_create_path, params: import_params
    expect(response).to redirect_to(dashboard_owner_path)
    expect(CdmBulkImport.last.collection_or_document_set).to eq(document_set)
    expect(CdmBulkImport.last.user).to eq(visitor)
  end

  it 'rejects missing or malformed destinations without creating a job' do
    login_as owner
    expect_any_instance_of(CdmBulkImport).not_to receive(:submit_background_task)
    [nil, 'D999999999', '999999999', 'bad', "D#{document_set.id}junk"].each do |selector|
      expect do
        post sc_collections_cdm_bulk_import_create_path, params: import_params.merge(collection_id: selector)
      end.not_to change(CdmBulkImport, :count)
      expect(response).to have_http_status(:not_found)
    end
  end

  it 'requires authentication before starting an import' do
    expect_any_instance_of(CdmBulkImport).not_to receive(:submit_background_task)
    expect do
      post sc_collections_cdm_bulk_import_create_path, params: import_params
    end.not_to change(CdmBulkImport, :count)
    expect(response).to redirect_to(dashboard_path)
  end

  it 'initializes an owner printout with the parent collection and document set' do
    login_as owner
    collection.update!(visibility: :private)
    path = configurable_printout_collection_work_path(owner, document_set, work)
    get download_collection_work_path(owner, document_set, work)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(path)
    get path, headers: { 'X-Requested-With' => 'XMLHttpRequest' }
    expect(response).to have_http_status(:ok)
    expect(assigns(:bulk_export).collection).to eq(collection)
    expect(assigns(:bulk_export).document_set).to eq(document_set)
    expect(assigns(:bulk_export).work).to eq(work)
    expect(assigns(:collection)).to eq(document_set)
    input = response.parsed_body.at_css('input[name="bulk_export[collection_id]"]')
    expect(input['value']).to eq(document_set.slug)
  end
  it 'keeps document-set printouts restricted to owners' do
    path = configurable_printout_collection_work_path(owner, document_set, work)
    login_as visitor
    get path
    expect(response).to have_http_status(:forbidden)
    reset!
    get path
    expect(response).to redirect_to(new_user_session_path)
  end
end
