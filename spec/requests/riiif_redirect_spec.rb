require 'spec_helper'

describe 'Riiif image service redirect' do
  let(:owner) { User.find_by(owner: true) || create(:user, owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, :with_image, work: work) }

  it 'redirects to the info.json endpoint instead of raising a NameError' do
    get "/image-service/#{page.id}"
    expect(response).to have_http_status(:redirect)
    expect(response.location).to include("/image-service/#{page.id}/info.json")
  end
end
