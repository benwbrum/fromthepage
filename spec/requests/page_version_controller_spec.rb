require 'spec_helper'

RSpec.describe PageVersionController do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let(:page) { create(:page, work: work, title: 'Current page') }
  let!(:first_version) do
    create(:page_version, page: page, user: owner, title: 'Version 1', transcription: 'first', created_on: 2.days.ago)
  end
  let!(:second_version) do
    create(:page_version, page: page, user: owner, title: 'Version 2', transcription: 'second', created_on: 1.day.ago)
  end

  it 'lists page versions for a page' do
    get collection_page_version_path(owner, collection, work, page)

    expect(response).to have_http_status(:ok)
  end

  it 'uses the requested comparison version' do
    get collection_page_version_path(owner, collection, work, page), params: { compare_version_id: first_version.id }

    expect(response).to have_http_status(:ok)
  end

  it 'uses the selected page version from params' do
    get page_version_list_path, params: { page_version_id: second_version.id }

    expect(response).to have_http_status(:ok)
  end
end
