require 'spec_helper'

describe SubjectHeadingsController, :subject_headings do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:field) { create(:transcription_field, :as_metadata, collection: collection, input_type: 'subject_headings', label: 'Topics', line_number: 1) }
  let!(:work) { create(:work, collection: collection, owner: owner) }
  let(:path) { collection_subject_headings_path(owner, collection, field) }
  let(:editor_path) { collection_edit_metadata_fields_path(owner, collection) }

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
    expect(response.body).to include('Save Subject Headings', 'Subject assignment guidelines (optional)')
    expect(response.body).to include('Download CSV template', 'Describe how subject headings should be assigned to documents in this collection. These guidelines will be used by AI Draft Metadata.')
    expect(Nokogiri::HTML(response.body).text).not_to include('inventory', 'UTF-8', 'attachments are not currently supported')
    expect(Nokogiri::HTML(response.body).at_css('#validate_authorities')['checked']).to be_nil
    get collection_subject_headings_template_path(owner, collection, field)
    expect(response.body).to start_with('heading,uri')
  end

  it 'uploads, displays inventory information and replaces headings' do
    login_as owner
    patch path, params: { file: upload_csv("heading\nOriginal\nOriginal.\n"), instructions: 'Use specific topics.' }
    expect(response).to redirect_to(editor_path)
    original = field.reload.subject_heading_inventory
    follow_redirect!
    expect(response.body).to include('Subject headings saved.')
    get path
    expect(response.body).to include('2 imported rows; 1 unique headings.', 'Use specific topics.', 'Not requested')
    patch path, params: { file: upload_csv("heading\nReplacement\n") }
    expect(field.reload.subject_heading_inventory.subject_headings.pluck(:heading)).to eq(['Replacement'])
    expect(SubjectHeadingInventory.exists?(original.id)).to be(false)
  end

  %w[upload guidelines].each do |save_type|
    it "returns the LiteBox redirect and success notice after a #{save_type} save" do
      import_headings(field) if save_type == 'guidelines'
      login_as owner
      parameters = { instructions: 'Prefer specific headings.' }
      parameters[:file] = upload_csv("heading\nAgriculture\n") if save_type == 'upload'
      patch path, params: parameters, headers: { 'X-Requested-With' => 'XMLHttpRequest' }
      expect(response).to have_http_status(:created)
      expect(response.headers['Location']).to eq(editor_path)
      get editor_path
      expect(response.body).to include('Subject headings saved.')
      expect(field.reload.subject_heading_instructions).to eq('Prefer specific headings.')
    end
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
    error = Nokogiri::HTML(response.body).at_css('.validation[role="alert"] .validation_summary li')
    expect(error.text).to include('requires a heading column')
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

  it 'denies configuration and report access to an unrelated user in a private project' do
    import_headings(field)
    collection.update!(visibility: :private)
    login_as create(:unique_user)
    get path
    expect(response).to be_redirect
    get collection_subject_headings_report_path(owner, collection, field)
    expect(response).to be_redirect
  end

  it 'serves reports through an authorized private endpoint' do
    inventory = import_headings(field)
    inventory.update!(report_csv: SubjectHeadings::Report.generate(inventory.source_rows))
    login_as owner
    get collection_subject_headings_report_path(owner, collection, field)
    expect(response.body).to eq(inventory.report_csv)
    expect(response.headers['Cache-Control']).to include('private', 'no-store')
  end

  it 'scopes configuration to the requested project' do
    other_collection = create(:collection, owner_user_id: owner.id, works: [])
    other_field = create(:transcription_field, :as_metadata, collection: other_collection, input_type: 'subject_headings')
    login_as owner
    get collection_subject_headings_path(owner, collection, other_field)
    expect(response).to have_http_status(:not_found)
  end

  it 'lets owners reupload an advisory report without accepting its suggestions' do
    inventory = import_headings(field, "heading\nLocal term\n")
    inventory.update!(report_csv: SubjectHeadings::Report.generate([
      { 'heading' => 'Local term', 'uri' => nil, 'suggested_heading' => 'Suggested term',
        'suggested_uri' => 'https://example.org/suggested', 'result' => 'possible_match', 'rationale' => 'Review this suggestion.' }
    ]))
    login_as owner
    get path
    expect(response.body).to include('Download validation report')
    get collection_subject_headings_report_path(owner, collection, field)
    report = response.body
    patch path, params: { file: upload_csv(report) }
    expect(response).to redirect_to(editor_path)
    expect(field.reload.subject_heading_inventory.subject_headings.pluck(:heading, :uri)).to eq([['Local term', nil]])

    edited = CSV.parse(report.delete_prefix("\uFEFF"), headers: true)
    edited.first['heading'] = 'Accepted term'
    edited.first['uri'] = 'https://example.org/accepted'
    patch path, params: { file: upload_csv(edited.to_csv) }
    expect(field.reload.subject_heading_inventory.subject_headings.pluck(:heading, :uri)).to eq([['Accepted term', 'https://example.org/accepted']])
  end

  it 'replaces inventories without changing work descriptions or the other team’s draft data' do
    import_headings(field)
    description = [{ 'label' => 'Title', 'value' => 'Existing description' }].to_json
    work.update!(metadata_description: description)
    candidates = { 'candidate_ids' => ['external-team-1'] }
    draft_metadata = { 'title' => 'Existing draft' }
    draft = create(:ai_work_metadata, work_id: work.id, subject_heading_candidates: candidates, metadata_json: draft_metadata)
    login_as owner
    expect do
      patch path, params: { file: upload_csv("heading\nReplacement\n") }
    end.not_to change(AiWorkMetadata, :count)
    expect(response).to redirect_to(editor_path)
    expect(work.reload.metadata_description).to eq(description)
    expect(draft.reload.subject_heading_candidates).to eq(candidates)
    expect(draft.metadata_json).to eq(draft_metadata)
  end

  it 'denies inventory configuration to ordinary transcribers' do
    import_headings(field)
    login_as create(:unique_user)
    get path
    expect(response).to have_http_status(:forbidden)
    patch path, params: { file: upload_csv("heading\nInjected\n") }
    expect(response).to have_http_status(:forbidden)
    expect(field.reload.subject_heading_inventory.subject_headings.pluck(:heading)).to eq(['Agriculture'])
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
end
