require 'spec_helper'

describe WorkController, '#ai_metadata' do
  let(:owner) { User.find_by(owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  it 'redirects to the metadata overview when no finished ai draft exists' do
    get collection_work_ai_metadata_path(owner, collection, work)

    expect(response).to redirect_to(metadata_overview_collection_work_path(owner, collection, work))
  end

  it 'redirects a signed-out visitor when a finished ai draft exists' do
    create(
      :ai_work_metadata,
      work_id: work.id,
      model: 'gemini-3.7-flash',
      status: :finished,
      metadata_json: {},
      reasoning: 'because it matches the text'
    )

    get collection_work_ai_metadata_path(owner, collection, work)

    expect(response).to redirect_to(metadata_overview_collection_work_path(owner, collection, work))
  end

  it 'shows the AI tab beside Metadata while editing metadata' do
    create(
      :ai_work_metadata,
      work_id: work.id,
      model: 'gemini-3.7-flash',
      status: :finished,
      metadata_json: {}
    )

    login_as owner
    get describe_collection_work_path(owner, collection, work)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(collection_work_ai_metadata_path(owner, collection, work))
  end

  it 'does not show the AI tab among the public work tabs' do
    create(
      :ai_work_metadata,
      work_id: work.id,
      model: 'gemini-3.7-flash',
      status: :finished,
      metadata_json: {}
    )

    get collection_work_about_path(owner, collection, work)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(collection_work_ai_metadata_path(owner, collection, work))
  end

  it 'shows the selected draft output, model selector, token usage, and reasoning' do
    field = create(:transcription_field, :as_metadata, :text_field, collection_id: collection.id, label: 'Title')
    create(
      :ai_work_metadata,
      work_id: work.id,
      model: 'gemini-3.7-flash',
      status: :finished,
      metadata_json: { field.id.to_s => 'Gemini title' }
    )
    create(
      :ai_work_metadata,
      work_id: work.id,
      model: 'claude-3-5-sonnet',
      status: :finished,
      metadata_json: { field.id.to_s => 'Claude title' },
      reasoning: 'Claude reasoning',
      metadata: { 'total_token_count' => 42 }
    )
    login_as owner

    get collection_work_ai_metadata_path(owner, collection, work, engine: 'claude')

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('claude-3-5-sonnet', 'Claude title', 'Claude reasoning', '42 tokens used')
    expect(response.body).to include('data-view-set="image"', 'data-view-set="transcript"', 'data-view-set="metadata"')
    expect(response.body).not_to include('data-view-set="ai"')
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

    expect(response).to redirect_to(metadata_overview_collection_work_path(owner, collection, work))
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
