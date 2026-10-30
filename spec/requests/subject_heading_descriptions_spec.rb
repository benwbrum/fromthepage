require 'spec_helper'

describe 'Subject heading descriptions and AI warnings', :subject_headings, type: :request do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: [], data_entry_type: Collection::DataEntryType::TEXT_AND_METADATA) }
  let!(:field) { create(:transcription_field, :as_metadata, collection: collection, input_type: 'subject_headings', label: 'Topics', line_number: 1) }
  let!(:work) { create(:work, collection: collection, owner: owner) }
  let!(:page) { create(:page, work: work) }
  let!(:inventory) { import_headings(field, "heading,uri\nAgriculture,https://id.loc.gov/authorities/subjects/sh85002415\nFarmers,\n") }

  before do
    Current.user = owner
    login_as owner
  end

  it 'saves and reloads multiple headings with their URIs and exposes no arbitrary options' do
    options = inventory.subject_headings.order(:id).to_a
    patch save_description_collection_work_path(owner, collection, work), params: { fields: { field.id.to_s => { 'Topics' => options.map(&:selection_value) } } }
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(work.reload.metadata_description).first['value']).to eq(options.map(&:snapshot))
    get describe_collection_work_path(owner, collection, work)
    document = Nokogiri::HTML(response.body)
    expect(document.css('.subject-heading-input option[selected]').size).to eq(2)
    expect(response.body).to include('https://id.loc.gov/authorities/subjects/sh85002415')
  end

  it 'displays retired snapshots, prevents new assignments, and permits removal' do
    option = inventory.subject_headings.first
    work.process_fields(field.id.to_s => { 'Topics' => [option.selection_value] })
    work.save!
    import_headings(field, "heading\nReplacement\n")
    get describe_collection_work_path(owner, collection, work)
    document = Nokogiri::HTML(response.body)
    expect(document.css('.subject-heading-input option').map(&:text)).to eq(['Agriculture'])
    expect(response.body).to include(option.uri)
    patch save_description_collection_work_path(owner, collection, work), params: { fields: { field.id.to_s => { 'Topics' => [''] } } }
    expect(JSON.parse(work.reload.metadata_description).first['value']).to eq([])
  end

  it 'rejects arbitrary strings in a forged request without changing saved metadata' do
    patch save_description_collection_work_path(owner, collection, work), params: { fields: { field.id.to_s => { 'Topics' => [{ heading: 'Invented', uri: nil }.to_json] } } }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(work.reload.metadata_description).to be_nil
  end

  it 'displays saved heading text and URI safely in metadata overview and history' do
    option = inventory.subject_headings.first
    work.process_fields(field.id.to_s => { 'Topics' => [option.selection_value] })
    work.save!
    get metadata_overview_collection_work_path(owner, collection, work)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Agriculture', option.uri)
  end

  %w[queued running failed completed not_requested].each do |status|
    it "shows the appropriate nonblocking warning at both AI entry points: #{status}" do
      inventory.update!(validation_status: status)
      # These are shared partials in the collection and work settings screens.
      get '/feature/ai_work_metadata/enable'
      get edit_collection_ai_transcriptions_path(owner, collection)
      expect(response).to have_http_status(:ok)
      document = Nokogiri::HTML(response.body)
      warning = document.at_css('.subject-heading-validation-warnings')
      if status == 'not_requested'
        expect(warning).to be_nil
      else
        expect(warning).to be_present
        expected = { 'queued' => 'validation is in progress', 'running' => 'validation is in progress', 'failed' => 'could not be completed', 'completed' => 'ready for review' }.fetch(status)
        expect(warning.text).to include(expected)
        expect(document.at_css('#ai-work-metadata-settings a[data-turbo-method="post"]')).to be_present
      end
      get edit_collection_work_ai_transcriptions_path(owner, collection, work)
      expect(response).to have_http_status(:ok)
      warning = Nokogiri::HTML(response.body).at_css('.subject-heading-validation-warnings')
      status == 'not_requested' ? expect(warning).to(be_nil) : expect(warning).to(be_present)
    end
  end
end
