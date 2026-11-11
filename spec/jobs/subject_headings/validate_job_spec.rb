require 'spec_helper'

describe SubjectHeadings::ValidateJob, :subject_headings do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:field) { create(:transcription_field, :as_metadata, collection: collection, input_type: 'subject_headings') }
  let(:token) { SecureRandom.uuid }
  let!(:validation) { validation_for(field, token: token) }
  let(:lookup) { instance_double(SubjectHeadings::AuthorityLookup, call: []) }

  before do
    Current.user = owner
    allow(SubjectHeadings::AuthorityLookup).to receive(:new).and_return(lookup)
    ActionMailer::Base.deliveries.clear
  end

  def run_job(id = validation.id)
    described_class.perform_now(user_id: owner.id, validation_id: id, token: token)
  end

  def report_results
    validation.reload.report_rows.map { |row| [row['heading'], row['result']] }
  end

  def set_rows(headings)
    validation.update!(source_rows: headings.map { |heading| { 'heading' => heading } }, row_count: headings.size, total_count: headings.size)
  end

  describe 'starting a validation' do
    it 'merges duplicate rows, queues the job and never saves headings to the field' do
      ActiveJob::Base.queue_adapter = :test
      upload = heading_upload("heading\nAgriculture\nAgriculture.\nAbolitionists\n", 'local.csv')
      started = nil
      expect { started = SubjectHeadingValidation.start!(field: field, upload: upload, user: owner) }
        .to have_enqueued_job(described_class).with(user_id: owner.id, validation_id: kind_of(Integer), token: kind_of(String))
      expect(started).to have_attributes(status: 'queued', filename: 'local.csv', row_count: 3, total_count: 2, duplicate_count: 1)
      expect(SubjectHeadingValidation.exists?(validation.id)).to be(false)
      expect(field.reload.subject_heading_inventory).to be_nil
    end

    it 'leaves a configured file untouched' do
      inventory = import_headings(field, "heading\nSaved\n")
      ActiveJob::Base.queue_adapter = :test
      SubjectHeadingValidation.start!(field: field, upload: heading_upload("heading\nOther\n"), user: owner)
      expect(field.reload.subject_heading_inventory.id).to eq(inventory.id)
      expect(inventory.subject_headings.pluck(:heading)).to eq(['Saved'])
    end

    it 'records a failure when enqueueing fails' do
      allow(described_class).to receive(:perform_later).and_return(false)
      started = SubjectHeadingValidation.start!(field: field, upload: heading_upload("heading\nOriginal\n"), user: owner)
      expect(started.reload.status).to eq('failed')
      expect(started.error_message).to include('could not be started')
      expect(started).to be_retryable
    end
  end

  it 'marks running during lookup, tracks progress and completes with a report and one email' do
    set_rows(%w[First Second])
    seen = []
    allow(lookup).to receive(:call) do
      seen << validation.reload.slice(:status, :processed_count)
      []
    end
    run_job
    expect(seen).to eq([{ 'status' => 'running', 'processed_count' => 0 }, { 'status' => 'running', 'processed_count' => 1 }])
    expect(validation.reload.status).to eq('completed')
    expect(validation.processed_count).to eq(2)
    expect(validation.report_csv).to include('no_match_found')
    expect(validation.completed_at).to be_present
    expect(validation.notified_at).to be_present
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq('Your subject heading validation is ready to review')
    expect(mail.to).to eq([owner.email])
    path = Rails.application.routes.url_helpers.collection_subject_headings_validation_path(owner, collection, field)
    expect(mail.html_part.body.decoded).to include(path, 'Review Validation', '2 headings were checked')
    run_job
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'never saves suggestions or headings to the field' do
    allow(lookup).to receive(:call).and_return([{ 'aLabel' => 'Different term', 'uri' => 'http://id.loc.gov/authorities/subjects/sh1' }])
    run_job
    expect(field.reload.subject_heading_inventory).to be_nil
    expect(validation.reload.report_csv).to include('possible_match')
    expect(validation.report_csv).not_to include('Different term')
  end

  it 'emails the requesting administrator when they differ from the collection owner' do
    requester = create(:unique_user, :admin)
    described_class.perform_now(user_id: requester.id, validation_id: validation.id, token: token)
    expect(ActionMailer::Base.deliveries.last.to).to eq([requester.email])
    expect(validation.reload.notified_at).to be_present
  end

  it 'completes with issues when lookup errors are recorded in a usable report' do
    allow(lookup).to receive(:call).and_raise(SubjectHeadings::AuthorityLookup::LookupError, 'Timed out')
    run_job
    expect(validation.reload.status).to eq('completed_with_issues')
    expect(validation.report_csv).to include('lookup_error', 'Timed out')
    expect(validation.report_csv).not_to include('no_match_found')
    expect(validation.counts).to eq(total: 1, exact: 0, possible: 0, errors: 1)
    expect(ActionMailer::Base.deliveries.last.html_part.body.decoded).to include('1 lookup errors')
    run_job
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'counts exact matches, possible matches and lookup errors' do
    set_rows(49.times.map { |i| "Term #{i}" })
    allow(lookup).to receive(:call) do |heading|
      raise SubjectHeadings::AuthorityLookup::LookupError, 'Authority response could not be processed.' if heading == 'Term 48'
      heading == 'Term 0' ? [{ 'aLabel' => 'Term 0', 'uri' => 'http://id.loc.gov/authorities/subjects/sh0', 'evidence' => 'authority', 'authority_type' => 'Subject' }] : []
    end
    run_job
    expect(validation.reload.counts).to eq(total: 49, exact: 1, possible: 47, errors: 1)
    expect(validation.badge_count).to eq(48)
    expect(validation).to be_lookup_errors
  end

  it 'fails when no report can be generated and sends failure wording' do
    allow(SubjectHeadings::Report).to receive(:generate).and_raise(ArgumentError, 'Cannot generate report')
    run_job
    expect(validation.reload.status).to eq('failed')
    expect(validation.report_csv).to be_nil
    expect(validation.counts).to be_nil
    expect(validation).to be_retryable
    expect(ActionMailer::Base.deliveries.last.subject).to eq('Your subject heading validation failed')
    expect(ActionMailer::Base.deliveries.last.html_part.body.decoded).to include('no report could be produced')
  end

  it 'stops querying after repeated failures and labels remaining rows not checked' do
    set_rows(10.times.map { |i| "Term #{i}" })
    allow(lookup).to receive(:call).and_raise(SubjectHeadings::AuthorityLookup::LookupError, 'Unavailable')
    run_job
    expect(lookup).to have_received(:call).exactly(3).times
    expect(report_results.first(3).map(&:last)).to eq(['lookup_error'] * 3)
    expect(report_results.drop(3).map(&:last)).to eq(['not_checked'] * 7)
    expect(validation.counts).to eq(total: 10, exact: 0, possible: 0, errors: 10)
  end

  it 'retries only lookup errors and unchecked headings, keeping earlier results in order' do
    set_rows(['=Formula', 'Second', 'Third'])
    allow(lookup).to receive(:call) do |heading|
      raise SubjectHeadings::AuthorityLookup::LookupError, 'Timed out' if heading == 'Second'
      []
    end
    run_job
    expect(report_results).to eq([['=Formula', 'no_match_found'], ['Second', 'lookup_error'], ['Third', 'no_match_found']])

    ActiveJob::Base.queue_adapter = :test
    expect(validation.queue!(user: owner)).to be_truthy
    expect(validation.reload).to have_attributes(status: 'queued', total_count: 1, processed_count: 0)
    allow(lookup).to receive(:call).and_return([])
    described_class.perform_now(user_id: owner.id, validation_id: validation.id, token: validation.token)
    expect(lookup).to have_received(:call).with('Second').twice
    expect(lookup).to have_received(:call).with('=Formula').once
    expect(validation.reload.status).to eq('completed')
    expect(report_results).to eq([['=Formula', 'no_match_found'], ['Second', 'no_match_found'], ['Third', 'no_match_found']])
    expect(validation.report_csv).to include("'=Formula").and(satisfy { |csv| !csv.include?("''=Formula") })
  end

  it 'does not offer a retry for a completed validation without lookup errors' do
    run_job
    expect(validation.reload).not_to be_retryable
    expect(validation.queue!(user: owner)).to be(false)
  end

  it 'ignores an old job after the field is validated again' do
    old_id = validation.id
    replacement = validation_for(field, "heading\nReplacement\n")
    run_job(old_id)
    expect(replacement.reload.status).to eq('queued')
    expect(replacement.report_csv).to be_nil
    expect(lookup).not_to have_received(:call)
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it 'does not overwrite or notify when a new validation replaces this one during lookup' do
    replacement = nil
    allow(lookup).to receive(:call) do
      replacement = validation_for(field, "heading\nReplacement\n")
      []
    end
    set_rows(%w[First Second])
    run_job
    expect(lookup).to have_received(:call).once
    expect(replacement.reload.status).to eq('queued')
    expect(replacement.report_csv).to be_nil
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it 'ignores duplicate running deliveries and obsolete retry tokens' do
    validation.update!(status: 'running')
    run_job
    expect(lookup).not_to have_received(:call)
    validation.update!(status: 'queued', token: SecureRandom.uuid)
    run_job
    expect(lookup).not_to have_received(:call)
  end

  it 'can retry notification after an email failure without repeating authority lookups' do
    allow(UserMailer).to receive(:subject_heading_validation_finished).and_raise(IOError, 'SMTP temporarily unavailable')
    ActiveJob::Base.queue_adapter = :test
    expect { run_job }.to have_enqueued_job(described_class)
    expect(validation.reload.status).to eq('completed')
    expect(validation.notified_at).to be_nil
    allow(UserMailer).to receive(:subject_heading_validation_finished).and_call_original
    run_job
    expect(lookup).to have_received(:call).once
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    run_job
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'records unexpected processing failures' do
    allow(lookup).to receive(:call).and_raise(ArgumentError, 'Unexpected response')
    run_job
    expect(validation.reload.status).to eq('failed')
    expect(validation.error_message).to include('no report could be produced')
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'does not perform authority requests for a user without project permission' do
    stranger = create(:unique_user)
    described_class.perform_now(user_id: stranger.id, validation_id: validation.id, token: token)
    expect(validation.reload.status).to eq('failed')
    expect(validation).to be_retryable
    expect(lookup).not_to have_received(:call)
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it 'fails a queued attempt when its requester has been deleted' do
    described_class.perform_now(user_id: -1, validation_id: validation.id, token: token)
    expect(validation.reload.status).to eq('failed')
    expect(lookup).not_to have_received(:call)
  end

  it 'recovers an expired running claim on redelivery' do
    validation.update!(status: 'running', updated_at: 20.minutes.ago)
    run_job
    expect(validation.reload.status).to eq('completed')
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'does not let a stale delivery overwrite a recovered claim' do
    calls = 0
    allow(lookup).to receive(:call) do
      calls += 1
      if calls == 1
        validation.update_columns(updated_at: 20.minutes.ago)
        run_job
        [{ 'aLabel' => 'Stale suggestion', 'uri' => 'http://id.loc.gov/authorities/subjects/sh1' }]
      else
        []
      end
    end
    run_job
    expect(validation.reload.status).to eq('completed')
    expect(validation.report_csv).not_to include('Stale suggestion')
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'allows owner retry only after the running lease expires' do
    validation.update!(status: 'running')
    expect(validation.queue!(user: owner)).to be(false)
    validation.update_columns(updated_at: 20.minutes.ago)
    expect(validation.reload).to be_retryable
    ActiveJob::Base.queue_adapter = :test
    expect { validation.queue!(user: owner) }.to have_enqueued_job(described_class)
    expect(validation.reload.token).not_to eq(token)
  end

  it 'continues after isolated errors rather than stopping at three cumulative failures' do
    set_rows(8.times.map { |i| "Term #{i}" })
    allow(lookup).to receive(:call) do |heading|
      raise SubjectHeadings::AuthorityLookup::LookupError, 'HTTP 429' if %w[0 2 4].include?(heading.split.last)
      []
    end
    run_job
    expect(lookup).to have_received(:call).exactly(8).times
    expect(validation.reload.report_csv).not_to include('not_checked')
    expect(validation.status).to eq('completed_with_issues')
  end

  it 'writes correlated lifecycle, row progress and notification events to a dedicated file' do
    run_job
    contents = File.readlines(SubjectHeadings::ValidationLog.path(validation.id)).select { |line| line.include?(token) }.join
    expect(contents).to include('LC_AUTHORITY execution_started', 'LC_AUTHORITY processing_started',
      'LC_AUTHORITY row_started', 'LC_AUTHORITY row_finished', 'LC_AUTHORITY report_generated',
      'LC_AUTHORITY final_state_write', 'LC_AUTHORITY notification_finished', 'LC_AUTHORITY execution_ended')
    expect(contents).to include("\"validation_id\":#{validation.id}", token, '"job_id":', '"total_rows":1')
    expect(SubjectHeadings::AuthorityLookup).to have_received(:new).with(heartbeat: kind_of(Proc), logger: kind_of(ActiveSupport::Logger))
  end
end
