require 'spec_helper'

RSpec.describe 'IIIF collection import destinations', type: :request do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:source) { ScCollection.create!(at_id: "https://example.test/iiif/collection/#{SecureRandom.hex(8)}", label: 'Imported Library') }
  let(:arguments) do
    { sc_collection_id: source.id, collection_id: 'sc_collection',
      manifest_id: { '0' => '1' } }
  end

  before do
    Current.user = owner
    allow(Process).to receive(:spawn).and_return(12_345)
    allow(Process).to receive(:detach)
  end

  after { Warden.test_reset! }

  it 'renders the create-collection option without relying on JavaScript' do
    login_as owner
    label = 'Library "quoted" <draft>'
    stub_request(:get, source.at_id).to_return(body: {
      '@context' => 'http://iiif.io/api/presentation/2/context.json',
      '@id' => source.at_id, '@type' => 'sc:Collection', 'label' => label,
      'manifests' => [{ '@id' => 'https://example.test/iiif/manifest', '@type' => 'sc:Manifest', 'label' => 'Test manifest' }]
    }.to_json)
    post sc_collections_import_path, params: { at_id: source.at_id }
    expect(response).to have_http_status(:ok)
    option = response.parsed_body.at_css('#manifest_import option[value="sc_collection"]')
    expect(option.text).to eq("Create Collection: #{label}")
  end

  it 'creates the selected new collection and starts the import with its processing notice' do
    login_as owner
    expect do
      post sc_collections_import_collection_path, params: arguments
    end.to change(owner.collections, :count).by(1)
    imported = owner.collections.find_by!(title: 'Imported Library')
    expect(response).to redirect_to(collection_path(owner, imported))
    expect(flash[:notice]).to eq(I18n.t('sc_collections.import_collection.import_is_processing'))
    expect(Process).to have_received(:spawn).once
  end

  it 'supports a document-set selector without treating it as a collection URL' do
    set = create(:document_set, :public, collection: collection, owner_user_id: owner.id)
    login_as owner
    post sc_collections_import_collection_path, params: arguments.merge(collection_id: "D#{set.id}")
    expect(response).to redirect_to(collection_path(owner, collection))
    expect(Process).to have_received(:spawn).once
  end

  it 'preserves imports into an existing owned collection' do
    login_as owner
    post sc_collections_import_collection_path, params: arguments.merge(collection_id: collection.id)
    expect(response).to redirect_to(collection_path(owner, collection))
    expect(Process).to have_received(:spawn).once
  end

  it 'requires sign-in before creating a collection or starting an import' do
    expect do
      post sc_collections_import_collection_path, params: arguments
    end.not_to change(Collection, :count)
    expect(response).to have_http_status(:redirect)
    expect(Process).not_to have_received(:spawn)
  end

  it 'does not import into another owners document set' do
    visitor = create(:unique_user, :owner)
    set = create(:document_set, :public, collection: collection, owner_user_id: owner.id)
    login_as visitor
    post sc_collections_import_collection_path, params: arguments.merge(collection_id: "D#{set.id}")
    expect(response).to redirect_to(dashboard_path)
    expect(Process).not_to have_received(:spawn)
  end

  it 'returns 404 for missing source collections and document-set destinations' do
    login_as owner
    [arguments.merge(sc_collection_id: 999_999_999), arguments.merge(collection_id: 'D999999999')].each do |params|
      post sc_collections_import_collection_path, params: params
      expect(response).to have_http_status(:not_found)
    end
    expect(Process).not_to have_received(:spawn)
  end
end
