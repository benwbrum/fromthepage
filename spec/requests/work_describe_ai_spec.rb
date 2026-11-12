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

    document = Nokogiri::HTML(response.body)
    ai_draft_button = document.at_css('#ai-draft-metadata-fields')
    expect(ai_draft_button['class'].to_s.split).not_to include('outline')
    expect(ai_draft_button.next_element['id']).to eq('save_button_top')
  end

  it 'renders describe page without an ai draft option when none is available' do
    login_as owner

    get describe_collection_work_path(owner, collection, work)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include('data-view-set="ai"')
    expect(response.body).not_to include('id="ai-draft-metadata-fields"')
  end

  it 'renders the multi-model ai draft button and payload when gemini and claude drafts are both finished' do
    field = create(:transcription_field, :as_metadata, :text_field, collection_id: collection.id, label: 'Title')
    create(
      :ai_work_metadata,
      work_id: work.id,
      model: 'gemini-3.7-flash',
      status: :finished,
      metadata_json: { field.id.to_s => 'A Title' }
    )
    create(
      :ai_work_metadata,
      work_id: work.id,
      model: 'claude-3-5-sonnet',
      status: :finished,
      metadata_json: { field.id.to_s => 'Another Title' }
    )
    login_as owner

    get describe_collection_work_path(owner, collection, work)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('id="ai-draft-metadata-fields"')
    expect(response.body).to include('aiMetadataDraftByEngine')
    expect(response.body).to include('A Title')
    expect(response.body).to include('Another Title')
  end
end

describe WorkController, '#save_description' do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, data_entry_type: 'text_and_metadata') }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:field) { create(:transcription_field, :as_metadata, :text_field, label: 'Title', collection: collection) }

  before { Current.user = owner }

  it 'marks a finished AI draft reviewed so the work can serve as an example' do
    draft = create(:ai_work_metadata, work: work, status: :finished, metadata_json: {})
    unfinished = create(:ai_work_metadata, work: work, status: :processing, model: 'claude-sonnet-4-5')
    login_as owner

    patch save_description_collection_work_path(owner, collection, work), params: {
      fields: { field.id.to_s => { 'Title' => 'Corrected title' } }, save_to_transcribed: '1'
    }

    expect(draft.reload.reviewed_at).to be_present
    expect(unfinished.reload.reviewed_at).to be_nil
    expect(draft.sample_status).to eq('reviewed')
  end
end

describe WorkController, '#describe with AI subject heading suggestions' do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, data_entry_type: 'text_and_metadata') }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }
  let!(:field) { create(:transcription_field, :as_metadata, label: 'Subjects', input_type: 'subject_headings', collection: collection) }

  before do
    Current.user = owner
    import_headings(field, "heading\nAgriculture\nCotton\n")
  end

  it 'puts the suggested headings in the AI draft and keeps retired suggestions selectable' do
    create(:ai_work_metadata, work: work, status: :finished, metadata_json: {},
                              subject_heading_candidates: { field.id.to_s => [{ 'heading' => 'Cotton' }, { 'heading' => 'Retired heading' }] })
    login_as owner

    get describe_collection_work_path(owner, collection, work)

    expect(response.body).to include(%("#{field.id}":["Cotton","Retired heading"]))
    options = Nokogiri::HTML(response.body).css("select[name^='fields[#{field.id}]'] option").map(&:text)
    expect(options).to include('Agriculture', 'Cotton', 'Retired heading')
  end
end
