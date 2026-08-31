require 'spec_helper'

describe WorkController, '#describe' do
  before do
    Current.user = owner
  end

  let(:owner) { User.find_by(owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  it 'renders describe page with ai draft available' do
    create(
      :ai_work_metadata,
      work_id: work.id,
      model: 'gemini-3.7-flash',
      status: :finished,
      metadata_json: {},
      reasoning: 'because'
    )
    login_as owner

    get describe_collection_work_path(owner, collection, work)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('page-ai')
  end

  it 'renders describe page without an ai draft option when none is available' do
    login_as owner

    get describe_collection_work_path(owner, collection, work)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('data-view-set="ai"')
  end
end
