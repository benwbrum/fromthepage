require 'spec_helper'

describe WorkController, '#ai_metadata' do
  let(:owner) { User.find_by(owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  it 'redirects to the about tab when no finished ai draft exists' do
    get collection_work_ai_metadata_path(owner, collection, work)

    expect(response).to redirect_to(collection_work_about_path(owner, collection, work))
  end

  it 'is visible to a signed-out visitor when a finished ai draft exists' do
    create(
      :ai_work_metadata,
      work_id: work.id,
      model: 'gemini-3.7-flash',
      status: :finished,
      metadata_json: {},
      reasoning: 'because it matches the text'
    )

    get collection_work_ai_metadata_path(owner, collection, work)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('gemini-3.7-flash')
    expect(response.body).to include('because it matches the text')
  end

  it 'shows the AI tab alongside the other public work tabs when a finished ai draft exists' do
    create(
      :ai_work_metadata,
      work_id: work.id,
      model: 'gemini-3.7-flash',
      status: :finished,
      metadata_json: {}
    )

    get collection_work_about_path(owner, collection, work)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(collection_work_ai_metadata_path(owner, collection, work))
  end

  it 'does not show the AI tab when no finished ai draft exists' do
    get collection_work_about_path(owner, collection, work)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(collection_work_ai_metadata_path(owner, collection, work))
  end

  it 'redirects a non-owner visitor when the collection has ai drafts disabled' do
    collection.update!(ai_draft_disabled: true)
    create(
      :ai_work_metadata,
      work_id: work.id,
      model: 'gemini-3.7-flash',
      status: :finished,
      metadata_json: {}
    )

    get collection_work_ai_metadata_path(owner, collection, work)

    expect(response).to redirect_to(collection_work_about_path(owner, collection, work))
  end

  it 'is visible to the owner even when the collection has ai drafts disabled' do
    collection.update!(ai_draft_disabled: true)
    create(
      :ai_work_metadata,
      work_id: work.id,
      model: 'gemini-3.7-flash',
      status: :finished,
      metadata_json: {}
    )
    login_as owner

    get collection_work_ai_metadata_path(owner, collection, work)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('gemini-3.7-flash')
  end
end
