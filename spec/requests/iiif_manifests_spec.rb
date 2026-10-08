require 'spec_helper'

describe 'IIIF Manifests API' do
  fixtures [:collections]

  let(:owner) { create(:user, owner: true) }

  it 'returns JSON' do
    get iiif_manifest_path(1)
    expect(response.content_type).to eq("application/json; charset=utf-8")
  end

  it "returns a URL with the corresponding ID" do
    get iiif_manifest_path(1)
    json = JSON.parse(response.body)
    expect(json['within']['@id']).to eql("http://www.example.com/iiif/collection/cs-pierce")
  end

  it 'blocks access to private collections without API access' do
    collection = create(:collection, :private, owner_user_id: owner.id)
    work = create(:work, collection: collection, owner_user_id: owner.id)

    get iiif_manifest_path(work.id)

    expect(response).to have_http_status(:forbidden)
    expect(response.body).to eq('This collection is private. The collection owner must enable API access to it or make it public for it to appear.')
  end
end
