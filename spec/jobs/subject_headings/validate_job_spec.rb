require 'spec_helper'

describe SubjectHeadings::ValidateJob, :subject_headings do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:field) { create(:transcription_field, :as_metadata, collection: collection, input_type: 'subject_headings') }
  let(:inventory) { import_headings(field) }
  let(:token) { SecureRandom.uuid }
  let(:lookup) { instance_double(SubjectHeadings::AuthorityLookup, call: []) }

  before do
    Current.user = owner
    allow(SubjectHeadings::AuthorityLookup).to receive(:new).and_return(lookup)
    inventory.update!(validation_status: 'queued', validation_token: token)
    ActionMailer::Base.deliveries.clear
  end

  def run_job
    described_class.perform_now(user_id: owner.id, inventory_id: inventory.id, token: token)
  end

  it 'queues optional validation without delaying inventory availability' do
    inventory.update!(validation_status: 'not_requested')
    ActiveJob::Base.queue_adapter = :test
    expect { inventory.queue_validation!(user: owner) }.to have_enqueued_job(described_class).with(user_id: owner.id, inventory_id: inventory.id, token: kind_of(String))
    expect(inventory.reload.validation_status).to eq('queued')
    expect(inventory.subject_headings.count).to eq(1)
  end

  it 'keeps the inventory usable and retryable when enqueueing fails' do
    inventory.update!(validation_status: 'not_requested')
    allow(described_class).to receive(:perform_later).and_return(false)
    inventory.queue_validation!(user: owner)
    expect(inventory.reload.validation_status).to eq('failed')
    expect(inventory.validation_error).to include('could not be queued')
    expect(inventory.subject_headings.count).to eq(1)
  end

  it 'marks running during lookup and completes with a report and one email' do
    allow(lookup).to receive(:call) do
      expect(inventory.reload.validation_status).to eq('running')
      []
    end
    run_job
    expect(inventory.reload.validation_status).to eq('completed')
    expect(inventory.report_csv).to include('no_match_found')
    expect(inventory.completed_at).to be_present
    expect(inventory.notified_at).to be_present
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq('Your subject headings authority check report is ready')
    expect(mail.to).to eq([owner.email])
    path = Rails.application.routes.url_helpers.collection_subject_headings_path(owner, collection, field)
    expect(mail.html_part.body.decoded).to include(path)
    expect(mail.html_part.body.decoded).to include('Download authority check report')
    run_job
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'never applies suggestions to the active inventory' do
    before = inventory.subject_headings.first.attributes.slice('heading', 'uri')
    allow(lookup).to receive(:call).and_return([{ 'aLabel' => 'Different term', 'uri' => 'http://id.loc.gov/authorities/subjects/sh1' }])
    run_job
    expect(inventory.subject_headings.first.attributes.slice('heading', 'uri')).to eq(before)
    expect(inventory.reload.report_csv).to include('possible_match')
    expect(inventory.report_csv).not_to include('Different term')
  end

  it 'emails the requesting administrator when they differ from the collection owner' do
    requester = create(:unique_user, :admin)
    described_class.perform_now(user_id: requester.id, inventory_id: inventory.id, token: token)
    expect(ActionMailer::Base.deliveries.last.to).to eq([requester.email])
    expect(inventory.reload.notified_at).to be_present
  end

  it 'completes with issues when lookup errors are recorded in a usable report' do
    allow(lookup).to receive(:call).and_raise(SubjectHeadings::AuthorityLookup::LookupError, 'Timed out')
    run_job
    expect(inventory.reload.validation_status).to eq('completed_with_issues')
    expect(inventory.subject_headings.count).to eq(1)
    expect(inventory.report_csv).to include('lookup_error', 'Timed out')
    expect(inventory.report_csv).not_to include('no_match_found')
    expect(ActionMailer::Base.deliveries.last.subject).to include('completed with 1 lookup error')
    run_job
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'retains successful rows in a partial report' do
    inventory.update!(source_rows: [{ 'heading' => 'First' }, { 'heading' => 'Second' }])
    allow(lookup).to receive(:call).with('First').and_return([])
    allow(lookup).to receive(:call).with('Second').and_raise(SubjectHeadings::AuthorityLookup::LookupError, 'Network failure')
    run_job
    expect(inventory.reload.validation_status).to eq('completed_with_issues')
    expect(inventory.report_csv).to include('no_match_found', 'lookup_error')
  end

  it 'reports 48 successful headings and one issue without a confusing zero-skipped message' do
    inventory.update!(source_rows: 49.times.map { |i| { 'heading' => "Term #{i}" } })
    allow(lookup).to receive(:call).with('Term 48').and_raise(SubjectHeadings::AuthorityLookup::LookupError, 'Authority response could not be processed.')
    original = inventory.subject_headings.pluck(:heading, :uri)
    run_job
    expect(inventory.reload.validation_status).to eq('completed_with_issues')
    expect(inventory.authority_check_counts).to eq(total: 49, successful: 48, exact: 0, review: 48, failed: 1, unattempted: 0)
    expect(inventory.authority_check_title).to eq('Authority check completed with 1 lookup error')
    expect(inventory.authority_check_summary).to eq('0 exact-label matches · 48 other results for review · 1 lookup error')
    mail = ActionMailer::Base.deliveries.last
    expect(mail.subject).to eq('Authority check completed with 1 lookup error')
    expect(mail.html_part.body.decoded).to include('0 exact-label matches · 48 other results for review · 1 lookup error', 'Download authority check report', 'copy its value into the heading or uri column')
    expect(mail.html_part.body.decoded).not_to include('0 headings were not checked')
    expect(inventory.subject_headings.pluck(:heading, :uri)).to eq(original)
  end

  it 'fails when no report can be generated and sends failure wording' do
    allow(SubjectHeadings::Report).to receive(:generate).and_raise(ArgumentError, 'Cannot generate report')
    run_job
    expect(inventory.reload.validation_status).to eq('failed')
    expect(inventory.report_csv).to be_nil
    expect(inventory.authority_check_counts).to be_nil
    expect(ActionMailer::Base.deliveries.last.subject).to eq('Your subject headings authority check failed')
    expect(ActionMailer::Base.deliveries.last.html_part.body.decoded).to include('No usable authority check report could be produced')
  end

  it 'stops querying after repeated failures and labels remaining rows not checked' do
    inventory.update!(source_rows: 10.times.map { |i| { 'heading' => "Term #{i}" } })
    allow(lookup).to receive(:call).and_raise(SubjectHeadings::AuthorityLookup::LookupError, 'Unavailable')
    run_job
    expect(lookup).to have_received(:call).exactly(3).times
    rows = CSV.parse(inventory.reload.report_csv.delete_prefix("\uFEFF"), headers: true)
    expect(rows.first(3).map { |row| row['result'] }).to eq(['lookup_error'] * 3)
    expect(rows.drop(3).map { |row| row['result'] }).to eq(['not_checked'] * 7)
    expect(rows[-1]['rationale']).to include('No request made')
    expect(inventory.authority_check_counts).to eq(total: 10, successful: 0, exact: 0, review: 0, failed: 3, unattempted: 7)
  end

  it 'ignores an old job after replacement' do
    old_id = inventory.id
    replacement = import_headings(field, "heading\nReplacement\n")
    described_class.perform_now(user_id: owner.id, inventory_id: old_id, token: token)
    expect(replacement.reload.validation_status).to eq('not_requested')
    expect(replacement.report_csv).to be_nil
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it 'does not overwrite or notify when an inventory is replaced during lookup' do
    replacement = nil
    allow(lookup).to receive(:call) do
      replacement = import_headings(field, "heading\nReplacement\n")
      []
    end
    run_job
    expect(replacement.reload.validation_status).to eq('not_requested')
    expect(replacement.report_csv).to be_nil
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it 'ignores duplicate running deliveries and obsolete retry tokens' do
    inventory.update!(validation_status: 'running')
    run_job
    expect(lookup).not_to have_received(:call)
    inventory.update!(validation_status: 'queued', validation_token: SecureRandom.uuid)
    run_job
    expect(lookup).not_to have_received(:call)
  end

  it 'can retry notification after an email failure without repeating authority lookups' do
    allow(UserMailer).to receive(:subject_heading_validation_finished).and_raise(IOError, 'SMTP temporarily unavailable')
    ActiveJob::Base.queue_adapter = :test
    expect { run_job }.to have_enqueued_job(described_class)
    expect(inventory.reload.validation_status).to eq('completed')
    expect(inventory.notified_at).to be_nil
    allow(UserMailer).to receive(:subject_heading_validation_finished).and_call_original
    run_job
    expect(lookup).to have_received(:call).once
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    run_job
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'records unexpected processing failures without corrupting available headings' do
    allow(lookup).to receive(:call).and_raise(ArgumentError, 'Unexpected response')
    run_job
    expect(inventory.reload.validation_status).to eq('failed')
    expect(inventory.validation_error).to include('uploaded headings remain available')
    expect(inventory.subject_headings.count).to eq(1)
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'does not perform authority requests for a user without project permission' do
    stranger = create(:unique_user)
    described_class.perform_now(user_id: stranger.id, inventory_id: inventory.id, token: token)
    expect(inventory.reload.validation_status).to eq('failed')
    expect(inventory).to be_validation_retryable
    expect(lookup).not_to have_received(:call)
    expect(ActionMailer::Base.deliveries).to be_empty
  end
  it 'fails a queued attempt when its requester has been deleted' do
    described_class.perform_now(user_id: -1, inventory_id: inventory.id, token: token)
    expect(inventory.reload.validation_status).to eq('failed')
    expect(lookup).not_to have_received(:call)
  end

  it 'recovers an expired running claim on redelivery' do
    inventory.update!(validation_status: 'running', updated_at: 20.minutes.ago)
    run_job
    expect(inventory.reload.validation_status).to eq('completed')
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'does not let a stale delivery overwrite a recovered claim' do
    calls = 0
    allow(lookup).to receive(:call) do
      calls += 1
      if calls == 1
        inventory.update_columns(updated_at: 20.minutes.ago)
        run_job
        [{ 'aLabel' => 'Stale suggestion', 'uri' => 'http://id.loc.gov/authorities/subjects/sh1' }]
      else
        []
      end
    end
    run_job
    expect(inventory.reload.validation_status).to eq('completed')
    expect(inventory.report_csv).not_to include('Stale suggestion')
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it 'allows owner retry only after the running lease expires' do
    inventory.update!(validation_status: 'running')
    expect(inventory.queue_validation!(user: owner)).to be(false)
    inventory.update_columns(updated_at: 20.minutes.ago)
    expect(inventory).to be_validation_retryable
    ActiveJob::Base.queue_adapter = :test
    expect { inventory.queue_validation!(user: owner) }.to have_enqueued_job(described_class)
    expect(inventory.reload.validation_token).not_to eq(token)
  end

  it 'continues after isolated errors rather than stopping at three cumulative failures' do
    inventory.update!(source_rows: 8.times.map { |i| { 'heading' => "Term #{i}" } })
    allow(lookup).to receive(:call) do |heading|
      raise SubjectHeadings::AuthorityLookup::LookupError, 'HTTP 429' if %w[0 2 4].include?(heading.split.last)
      []
    end
    run_job
    expect(lookup).to have_received(:call).exactly(8).times
    expect(inventory.reload.report_csv).not_to include('not_checked')
    expect(inventory.validation_status).to eq('completed_with_issues')
  end

  it 'writes correlated lifecycle, row progress and notification events to a dedicated file' do
    run_job
    contents = File.readlines(SubjectHeadings::ValidationLog.path(inventory.id)).select { |line| line.include?(token) }.join
    expect(contents).to include('LC_AUTHORITY execution_started', 'LC_AUTHORITY processing_started',
      'LC_AUTHORITY row_started', 'LC_AUTHORITY row_finished', 'LC_AUTHORITY report_generated',
      'LC_AUTHORITY final_state_write', 'LC_AUTHORITY notification_finished', 'LC_AUTHORITY execution_ended')
    expect(contents).to include("\"inventory_id\":#{inventory.id}", token, '"job_id":', '"total_rows":1')
    expect(contents).not_to include('[LC authority]')
    expect(SubjectHeadings::AuthorityLookup).to have_received(:new).with(heartbeat: kind_of(Proc), logger: kind_of(ActiveSupport::Logger))
  end
end
