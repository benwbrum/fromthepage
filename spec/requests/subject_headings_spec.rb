require 'spec_helper'

describe SubjectHeadingsController, :subject_headings do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:field) { create(:transcription_field, :as_metadata, collection: collection, input_type: 'subject_headings', label: 'Topics', line_number: 1) }
  let!(:work) { create(:work, collection: collection, owner: owner) }
  let(:path) { collection_subject_headings_path(owner, collection, field) }

  before { Current.user = owner }

  def upload_csv(content)
    file = Tempfile.new(['headings', '.csv'])
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file.path, 'text/csv')
  end

  it 'lets an owner create the datatype through the existing field editor' do
    login_as owner
    post transcription_field_add_fields_path, params: { collection_id: collection.id, field_type: 'metadata', transcription_fields: [{ label: 'New Topics', input_type: 'subject_headings', line_number: '1' }] }
    expect(collection.metadata_fields.find_by(label: 'New Topics')).to be_subject_headings
    get collection_edit_metadata_fields_path(owner, collection)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Configure Subject Headings', 'Subject Headings (LCSH)')
  end

  it 'opens the initial configuration modal and downloads a template' do
    login_as owner
    get path, headers: { 'X-Requested-With' => 'XMLHttpRequest' }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Import Headings', 'Instructions for AI Draft Metadata')
    expect(Nokogiri::HTML(response.body).at_css('#validate_authorities')['checked']).to be_nil
    get collection_subject_headings_template_path(owner, collection, field)
    expect(response.body).to start_with('heading,uri')
  end

  it 'uploads, displays inventory information and replaces headings' do
    login_as owner
    patch path, params: { file: upload_csv("heading\nOriginal\nOriginal.\n"), instructions: 'Use specific topics.' }
    expect(response).to redirect_to(path)
    original = field.reload.subject_heading_inventory
    get path
    expect(response.body).to include('2 imported rows; 1 unique selectable headings.', 'Use specific topics.', 'Not requested')
    patch path, params: { file: upload_csv("heading\nReplacement\n") }
    expect(field.reload.subject_heading_inventory.subject_headings.pluck(:heading)).to eq(['Replacement'])
    expect(SubjectHeadingInventory.exists?(original.id)).to be(false)
  end

  it 'queues validation only when requested and allows retry after failure' do
    login_as owner
    ActiveJob::Base.queue_adapter = :test
    expect { patch path, params: { file: upload_csv("heading\nOriginal\n"), validate_authorities: '1' } }.to have_enqueued_job(SubjectHeadings::ValidateJob)
    inventory = field.reload.subject_heading_inventory
    expect(inventory.validation_status).to eq('queued')
    post collection_subject_headings_retry_path(owner, collection, field)
    expect(response).to have_http_status(:conflict)
    inventory.update!(validation_status: 'failed')
    old_token = inventory.validation_token
    expect { post collection_subject_headings_retry_path(owner, collection, field) }.to have_enqueued_job(SubjectHeadings::ValidateJob)
    expect(inventory.reload.validation_token).not_to eq(old_token)
  end

  it 'reports malformed CSV without deleting the current inventory' do
    inventory = import_headings(field)
    login_as owner
    patch path, params: { file: upload_csv('bad header') }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include('requires a heading column')
    expect(field.reload.subject_heading_inventory.id).to eq(inventory.id)
  end

  it 'saves guidance without a replacement' do
    inventory = import_headings(field)
    login_as owner
    patch path, params: { instructions: 'Ignore passing mentions.' }
    expect(field.reload.subject_heading_instructions).to eq('Ignore passing mentions.')
    expect(field.subject_heading_inventory.id).to eq(inventory.id)
  end

  it 'rejects a missing initial file and excessive guidance' do
    login_as owner
    patch path, params: { instructions: 'Only guidance' }
    expect(response).to have_http_status(:unprocessable_entity)
    import_headings(field)
    patch path, params: { instructions: 'a' * 20_001 }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it 'blocks unauthorized field creation, deletion and cross-collection edits' do
    inventory = import_headings(field)
    login_as create(:unique_user, :owner)
    post transcription_field_add_fields_path, params: { collection_id: collection.id, field_type: 'metadata', transcription_fields: [{ label: 'Bad', input_type: 'subject_headings', line_number: '1' }] }
    expect(response).to have_http_status(:forbidden)
    get transcription_field_delete_path(field_id: field.id, collection_id: collection.id)
    expect(response).to have_http_status(:forbidden)
    expect(inventory.reload).to be_present
  end

  it 'denies search and report access to an unrelated user in a private project' do
    import_headings(field)
    collection.update!(visibility: :private)
    login_as create(:unique_user)
    get collection_subject_headings_search_path(owner, collection, field)
    expect(response).to be_redirect
    get collection_subject_headings_report_path(owner, collection, field)
    expect(response).to be_redirect
  end

  it 'limits remote search results, supports pagination and does not render inventory options' do
    import_headings(field, "heading\n#{3000.times.map { |i| "Topic #{i}" }.join("\n")}\n")
    login_as owner
    search_path = collection_subject_headings_search_path(owner, collection, field)
    get search_path, params: { term: 'Topic', page: 1 }
    first = JSON.parse(response.body)
    expect(first['results'].size).to eq(30)
    expect(first['pagination']['more']).to be(true)
    get search_path, params: { term: 'Topic', page: 2 }
    expect(JSON.parse(response.body)['results'].map { |r| r['id'] } & first['results'].map { |r| r['id'] }).to be_empty
    get collection_edit_metadata_fields_path(owner, collection)
    expect(Nokogiri::HTML(response.body).css('.subject-heading-input option').size).to eq(0)
  end

  it 'escapes wildcard search and does not allow foreign field IDs' do
    import_headings(field)
    login_as owner
    get collection_subject_headings_search_path(owner, collection, field), params: { term: '%' }
    expect(JSON.parse(response.body)['results']).to be_empty
    other_collection = create(:collection, owner_user_id: owner.id, works: [])
    other = create(:transcription_field, :as_metadata, collection: other_collection, input_type: 'subject_headings')
    get collection_subject_headings_path(owner, collection, other)
    expect(response).to have_http_status(:not_found)
  end

  it 'serves reports through an authorized private endpoint' do
    inventory = import_headings(field)
    inventory.update!(report_csv: SubjectHeadings::Report.generate(inventory.source_rows))
    login_as owner
    get collection_subject_headings_report_path(owner, collection, field)
    expect(response.body).to eq(inventory.report_csv)
    expect(response.headers['Cache-Control']).to include('private', 'no-store')
  end

  [nil, :nonowner].each do |role|
    it "rejects configuration and report access for #{role || 'anonymous visitors'}" do
      login_as create(:unique_user, :owner) if role
      get path
      expect(response).to have_http_status(:forbidden)
      patch path, params: { file: upload_csv("heading\nInjected\n") }
      expect(response).to have_http_status(:forbidden)
      get collection_subject_headings_report_path(owner, collection, field)
      expect(response).to have_http_status(:forbidden)
      post collection_subject_headings_retry_path(owner, collection, field)
      expect(response).to have_http_status(:forbidden)
      expect(field.reload.subject_heading_inventory).to be_nil
    end
  end

  it 'allows signed-in transcribers to search but not configure' do
    import_headings(field)
    login_as create(:unique_user)
    get collection_subject_headings_search_path(owner, collection, field)
    expect(response).to have_http_status(:ok)
    get path
    expect(response).to have_http_status(:forbidden)
  end
end
