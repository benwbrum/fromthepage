require 'spec_helper'

describe SubjectHeadingsController, :subject_headings do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:field) { create(:transcription_field, :as_metadata, collection: collection, input_type: 'subject_headings', label: 'Topics', line_number: 1) }
  let!(:work) { create(:work, collection: collection, owner: owner) }
  let(:path) { collection_subject_headings_path(owner, collection, field) }
  let(:editor_path) { collection_edit_metadata_fields_path(owner, collection) }
  let(:validation_path) { collection_subject_headings_validation_path(owner, collection, field) }
  let(:new_validation_path) { collection_new_subject_headings_validation_path(owner, collection, field) }
  let(:retry_path) { collection_subject_headings_retry_path(owner, collection, field) }
  let(:xhr) { { 'X-Requested-With' => 'XMLHttpRequest' } }

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
    html = Nokogiri::HTML(response.body)
    expect(html.css('select option').map(&:text)).to include('Subject Headings')
    expect(response.body).not_to include('(LCSH)')
    new_field = collection.metadata_fields.find_by(label: 'New Topics')
    buttons = html.at_css(".subject-heading-buttons[data-subject-heading-status-url-value$='/#{new_field.id}/subject_headings/buttons']")
    expect(buttons.css('a.button').map(&:text)).to eq(['Validate Subject Headings', 'Configure Subject Headings'])
  end

  it 'opens the initial configuration modal and downloads a template' do
    login_as owner
    get path, headers: { 'X-Requested-With' => 'XMLHttpRequest' }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Save Subject Headings', 'Subject Assignment Guidelines (optional)', 'Subject Headings File')
    expect(response.body).to include('Download CSV Template', 'Describe how subject headings should be assigned to documents in this collection. These guidelines will be used by AI Draft Metadata.')
    expect(response.body).to include('CSV with a heading column and an optional URI or ID column. Maximum 10,000 rows.')
    html = Nokogiri::HTML(response.body)
    expect(html.text).not_to include('inventory', 'UTF-8', 'attachments are not currently supported', 'Authority check')
    expect(html.at_css('#validate_authorities')).to be_nil
    expect(html.at_css("a[href='#{new_validation_path}']").text).to eq('Validate Subject Headings')
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
    expect(response.body).to include('2 rows · 1 unique heading · 1 duplicate row merged', 'Use specific topics.')
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

  it 'reports malformed CSV without deleting the current inventory' do
    inventory = import_headings(field)
    login_as owner
    patch path, params: { file: upload_csv('bad header') }
    expect(response).to have_http_status(:unprocessable_entity)
    error = Nokogiri::HTML(response.body).at_css('.input-file + .validation[role="alert"] .validation_summary li')
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
    get validation_path
    expect(response).to be_redirect
  end

  it 'scopes configuration to the requested project' do
    other_collection = create(:collection, owner_user_id: owner.id, works: [])
    other_field = create(:transcription_field, :as_metadata, collection: other_collection, input_type: 'subject_headings')
    login_as owner
    get collection_subject_headings_path(owner, collection, other_field)
    expect(response).to have_http_status(:not_found)
  end

  it 'lets owners upload a validation report in Configure without accepting its suggestions' do
    validation_for(field, "heading\nLocal term\n", status: 'completed', report_csv: SubjectHeadings::Report.generate([
      { 'heading' => 'Local term', 'uri' => nil, 'suggested_heading' => 'Suggested term',
        'suggested_uri' => 'https://example.org/suggested', 'result' => 'possible_match', 'rationale' => 'Review this suggestion.' }
    ]))
    login_as owner
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
      post retry_path
      expect(response).to have_http_status(:forbidden)
      get new_validation_path
      expect(response).to have_http_status(:forbidden)
      post validation_path, params: { file: upload_csv("heading\nInjected\n") }
      expect(response).to have_http_status(:forbidden)
      get validation_path
      expect(response).to have_http_status(:forbidden)
      get collection_subject_headings_buttons_path(owner, collection, field)
      expect(response).to have_http_status(:forbidden)
      expect(field.reload.subject_heading_inventory).to be_nil
      expect(field.subject_heading_validation).to be_nil
    end
  end

  describe 'validation' do
    before do
      login_as owner
      ActiveJob::Base.queue_adapter = :test
    end

    it 'opens the Validate modal with a disabled Start Validation button and a link to Configure' do
      get new_validation_path, headers: xhr
      html = Nokogiri::HTML(response.body)
      expect(html.at_css('h3').text).to eq('Validate Subject Headings')
      expect(html.text).to include('It does not save any headings to this field.', "Don't need to validate?", 'Maximum 10,000 rows.')
      expect(html.at_css('button[type=submit]').text).to eq('Start Validation')
      expect(html.at_css('button[type=submit]').key?('disabled')).to be(true)
      expect(html.at_css("a[href='#{path}']").text).to eq('Configure Subject Headings')
    end

    it 'starts a background validation without saving headings and shows progress on the field row' do
      expect do
        post validation_path, params: { file: upload_csv("heading\nAgriculture\nAgriculture.\nAbolitionists\n") }, headers: xhr
      end.to have_enqueued_job(SubjectHeadings::ValidateJob)
      expect(response).to have_http_status(:created)
      expect(response.headers['Location']).to eq(editor_path)
      expect(field.reload.subject_heading_inventory).to be_nil
      expect(field.subject_heading_validation).to have_attributes(status: 'queued', row_count: 3, total_count: 2)

      get editor_path
      html = Nokogiri::HTML(response.body)
      expect(html.at_css('.flash-info').text).to include('Validation started.', owner.email)
      buttons = html.at_css('.subject-heading-buttons')
      expect(buttons['data-controller']).to eq('subject-heading-status')
      expect(buttons.at_css('button[disabled]').text).to include('Validating… 0%')
      expect(buttons.css('a.button').map(&:text)).to eq(['Configure Subject Headings'])

      field.subject_heading_validation.update!(status: 'running', processed_count: 1)
      get collection_subject_headings_buttons_path(owner, collection, field), headers: xhr
      expect(Nokogiri::HTML(response.body).at_css('button[disabled]').text).to include('Validating… 50%')
    end

    it 'shows an inline error for an invalid file' do
      post validation_path, params: { file: upload_csv("subject\nAgriculture\n") }, headers: xhr
      expect(response).to have_http_status(:unprocessable_entity)
      html = Nokogiri::HTML(response.body)
      expect(html.at_css('.input-file + .validation[role="alert"]').text).to include('CSV requires a heading column.')
      expect(html.at_css('h3').text).to eq('Validate Subject Headings')
      expect(field.reload.subject_heading_validation).to be_nil
    end

    it 'reviews a finished validation with counts, report download and lookup error retry' do
      rows = 30.times.map { |i| { 'heading' => "Term #{i}", 'result' => 'exact_match' } }
      rows += 18.times.map { |i| { 'heading' => "Review #{i}", 'result' => 'possible_match' } }
      rows << { 'heading' => 'Problem', 'result' => 'lookup_error' }
      validation_for(field, status: 'completed_with_issues', report_csv: SubjectHeadings::Report.generate(rows), filename: 'local.csv')

      get editor_path
      review = Nokogiri::HTML(response.body).at_css("a.button[href='#{validation_path}']")
      expect(review.text).to include('Review Validation')
      expect(review.at_css('.subject-heading-badge').text).to eq('19')

      get validation_path, headers: xhr
      html = Nokogiri::HTML(response.body)
      expect(html.at_css('h3').text).to eq('Review Subject Heading Validation')
      expect(html.text).to include('Topics · local.csv', '49 headings were checked against Library of Congress authority records. Your headings have not been changed.')
      counts = html.css('.subject-heading-counts > div').map { |cell| [cell.at_css('dt').text, cell.at_css('dd').text] }
      expect(counts).to eq([['Exact matches', '30'], ['Possible matches to review', '18'], ['Lookup errors', '1']])
      expect(html.css('h4').map(&:text)).to eq(['Apply Suggestions', 'Lookup Errors'])
      expect(html.text).to include('1 heading could not be checked', 'No headings are saved to this field until you upload a file in Configure Subject Headings.')
      expect(html.at_css("a.button[href='#{collection_subject_headings_report_path(owner, collection, field)}']").text).to eq('Download Validation Report')
      expect(html.at_css("form[action='#{retry_path}'] button").text).to eq('Retry Lookup Errors')
      expect(html.at_css("a[href='#{new_validation_path}']").text).to eq('Validate Another File')

      expect { post retry_path, headers: xhr }.to have_enqueued_job(SubjectHeadings::ValidateJob)
      expect(response).to have_http_status(:created)
      expect(field.subject_heading_validation.reload).to have_attributes(status: 'queued', total_count: 1)
      post retry_path
      expect(response).to have_http_status(:conflict)
    end

    it 'omits lookup errors when there are none and does not allow a retry' do
      validation_for(field, status: 'completed', report_csv: SubjectHeadings::Report.generate([{ 'heading' => 'Agriculture', 'result' => 'exact_match' }]))
      get validation_path, headers: xhr
      html = Nokogiri::HTML(response.body)
      expect(html.css('h4').map(&:text)).to eq(['Apply Suggestions'])
      expect(html.text).not_to include('Retry Lookup Errors')
      post retry_path
      expect(response).to have_http_status(:conflict)
      get editor_path
      expect(Nokogiri::HTML(response.body).at_css('.subject-heading-badge')).to be_nil
    end

    it 'shows a failed validation with a retry' do
      validation_for(field, status: 'failed', error_message: 'Validation failed and no report could be produced. Please try again.')
      get validation_path, headers: xhr
      html = Nokogiri::HTML(response.body)
      expect(html.at_css('.validation[role="alert"]').text).to include('no report could be produced')
      expect(html.at_css("form[action='#{retry_path}'] button").text).to eq('Try Validation Again')
    end

    it 'serves reports through an authorized private endpoint' do
      validation = validation_for(field, status: 'completed', report_csv: SubjectHeadings::Report.generate([{ 'heading' => 'Agriculture' }]), filename: 'local.csv')
      get collection_subject_headings_report_path(owner, collection, field)
      expect(response.body).to eq(validation.report_csv)
      expect(response.headers['Cache-Control']).to include('private', 'no-store')
      expect(response.headers['Content-Disposition']).to include('local_validation.csv')
    end

    it 'sends owners to the Validate modal before any validation exists' do
      get validation_path
      expect(response).to redirect_to(new_validation_path)
      get collection_subject_headings_report_path(owner, collection, field)
      expect(response).to have_http_status(:not_found)
    end

    it 'keeps the last validation when a file is configured' do
      validation = validation_for(field, status: 'completed', report_csv: SubjectHeadings::Report.generate([{ 'heading' => 'Agriculture', 'result' => 'possible_match' }]))
      patch path, params: { file: upload_csv("heading\nAgriculture\n") }
      expect(field.reload.subject_heading_validation.id).to eq(validation.id)
    end
  end
end
