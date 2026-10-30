require 'spec_helper'

describe 'Subject heading review regressions', :subject_headings, type: :request do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, collection: collection, owner: owner) }
  let!(:victim_owner) { create(:unique_user, :owner) }
  let!(:victim) { create(:collection, owner_user_id: victim_owner.id, works: []) }
  let!(:field) { create(:transcription_field, :as_metadata, collection: victim, label: 'Protected', input_type: 'subject_headings', line_number: 1) }

  before do
    Current.user = owner
    login_as owner
  end

  it 'authorizes the supplied collection for every field mutation despite a mismatched work' do
    common = { collection_id: victim.id, work_id: work.id }
    original = field.attributes
    post transcription_field_add_fields_path, params: common.merge(description_instructions: 'Injected', transcription_fields: [], field_type: 'metadata')
    expect(response).to have_http_status(:forbidden)
    get transcription_field_delete_path, params: common.merge(field_id: field.id)
    expect(response).to have_http_status(:forbidden)
    patch transcription_field_reorder_path, params: common.merge(field: [field.id], line: 4)
    expect(response).to have_http_status(:forbidden)
    expect(field.reload.attributes).to eq(original)
    expect(victim.reload.description_instructions).not_to eq('Injected')
  end

  it 'excludes subject headings from prompts and removes unsolicited subject output' do
    subject_field = create(:transcription_field, :as_metadata, collection: collection, input_type: 'subject_headings', label: 'Reserved subjects')
    text_field = create(:transcription_field, :as_metadata, :text_field, collection: collection, label: 'Title')
    import_headings(subject_field, instructions: 'Private guidance')
    prompt = AiWorkMetadata::Lib::PromptBuilder.new(work: work).build
    expect(prompt).not_to include('Reserved subjects', 'Private guidance', "\"#{subject_field.id}\":")
    validator = AiWorkMetadata::Lib::ResponseValidator.new(collection: collection, response_text: { text_field.id.to_s => 'Title', subject_field.id.to_s => 'Invented subject' }.to_json)
    expect(validator).to be_valid
    expect(validator.parsed_json).to eq(text_field.id.to_s => 'Title')
    validator = AiWorkMetadata::Lib::ResponseValidator.new(collection: collection, response_text: { text_field.id.to_s => 'Title' }.to_json)
    expect(validator).to be_valid
  end

  it 'offers owner recovery only for an expired validation claim' do
    subject_field = create(:transcription_field, :as_metadata, collection: collection, input_type: 'subject_headings')
    inventory = import_headings(subject_field)
    inventory.update!(validation_status: 'running', validation_token: 'old-attempt')
    path = collection_subject_headings_path(owner, collection, subject_field)
    retry_path = collection_subject_headings_retry_path(owner, collection, subject_field)
    get path
    expect(response.body).not_to include('Retry authority check')
    post retry_path
    expect(response).to have_http_status(:conflict)

    inventory.update_columns(updated_at: 20.minutes.ago)
    get path
    expect(response.body).to include('Retry authority check')
    ActiveJob::Base.queue_adapter = :test
    expect { post retry_path }.to have_enqueued_job(SubjectHeadings::ValidateJob)
    expect(response).to redirect_to(path)
    expect(inventory.reload.validation_status).to eq('queued')
    expect(inventory.validation_token).not_to eq('old-attempt')
  end
end
