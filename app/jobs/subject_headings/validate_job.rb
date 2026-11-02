class SubjectHeadings::ValidateJob < ApplicationJob
  queue_as :subject_headings

  def perform(user_id:, inventory_id:, token:)
    path = SubjectHeadings::ValidationLog.path(inventory_id)
    Rails.logger.info("LC_AUTHORITY job_log #{ { inventory_id: inventory_id, job_id: job_id, path: path.to_s }.to_json}")
    SubjectHeadings::ValidationLog.open(inventory_id: inventory_id, job_id: job_id, token: token) do |logger|
      @validation_logger = logger
      log_event('execution_started', user_id: user_id)
      begin
        validate(user_id: user_id, inventory_id: inventory_id, token: token)
      rescue StandardError => e
        log_exception('execution_failed', e)
        raise
      ensure
        log_event('execution_ended')
      end
    end
  end

  private

  def validate(user_id:, inventory_id:, token:)
    inventory = SubjectHeadingInventory.find_by(id: inventory_id, validation_token: token)
    unless inventory
      log_event('obsolete_inventory_or_token')
      return
    end
    requester = User.find_by(id: user_id)
    unless requester && (requester.admin? || requester.like_owner?(inventory.transcription_field.collection))
      log_event('requester_no_longer_authorized', user_id: user_id)
      SubjectHeadingInventory.where(id: inventory_id, validation_token: token, validation_status: 'queued')
        .update_all(validation_status: 'failed', completed_at: Time.current,
          validation_error: 'The requester no longer has project access. Please retry the authority check.')
      return
    end
    if %w[completed completed_with_issues failed].include?(inventory.validation_status)
      log_event('already_finalized', status: inventory.validation_status)
      notify(inventory, token, requester)
      return
    end
    # Compare-and-set prevents two deliveries from validating the same upload.
    claim_stamp = Time.current
    attempts = SubjectHeadingInventory.where(id: inventory_id, validation_token: token)
    claimable = attempts.where(validation_status: 'queued').or(
      attempts.where(validation_status: 'running').where('updated_at < ?', SubjectHeadingInventory::CLAIM_TIMEOUT.ago)
    )
    claimed = claimable.update_all(validation_status: 'running', updated_at: claim_stamp)
    log_event('claim_result', claimed: claimed, previous_status: inventory.validation_status)
    return unless claimed == 1

    begin
      heartbeat = lambda do
        next_stamp = Time.current
        owned = attempts.where(validation_status: 'running', updated_at: claim_stamp).update_all(updated_at: next_stamp)
        raise SubjectHeadings::AuthorityLookup::LookupError, 'Validation attempt is no longer current.' unless owned == 1
        claim_stamp = next_stamp
        log_event('lease_renewed', row: @row_index, at: claim_stamp.iso8601(6))
      end
      lookup = SubjectHeadings::AuthorityLookup.new(heartbeat: heartbeat, logger: @validation_logger)
      failures = 0
      consecutive_failures = 0
      skipped = 0
      memo = {}
      rows = inventory.source_rows
      log_event('processing_started', total_rows: rows.size)
      results = rows.each_with_index.map do |row, index|
        @row_index = index + 1
        log_event('row_started', row: @row_index, total_rows: rows.size, heading: row['heading'], uri: row['uri'])
        # A replacement deletes this import; stop spending requests immediately.
        next_stamp = Time.current
        owned = attempts.where(validation_status: 'running', updated_at: claim_stamp)
          .update_all(updated_at: next_stamp)
        unless owned == 1
          log_event('ownership_lost', row: @row_index)
          return
        end
        claim_stamp = next_stamp
        begin
          memo_key = [row['heading'], row['uri']]
          if consecutive_failures >= 3 && !memo.key?(memo_key)
            skipped += 1
            log_event('row_not_checked', row: @row_index, skipped: skipped, failures: failures)
            next row.merge('result' => 'not_checked', 'rationale' => 'No request made: further lookups stopped after three consecutive failed heading lookups. Please retry the authority check later.')
          end
          log_event('row_memo_hit', row: @row_index) if memo.key?(memo_key)
          hits = memo[memo_key] ||= row['uri'].present? ? lookup.call(row['heading'], identifier: row['uri']) : lookup.call(row['heading'])
          consecutive_failures = 0
          result = SubjectHeadings::Report.result(row, hits)
          log_event('row_finished', row: @row_index, result: result['result'], failures: failures, skipped: skipped)
          result
        rescue SubjectHeadings::AuthorityLookup::LookupError => e
          failures += 1
          consecutive_failures += 1
          log_event('row_lookup_error', row: @row_index, error: e.message, failures: failures, consecutive_failures: consecutive_failures)
          row.merge('result' => 'lookup_error', 'rationale' => e.message)
        end
      end
      log_event('report_generation_started', rows: results.size, failures: failures, skipped: skipped)
      report = SubjectHeadings::Report.generate(results)
      log_event('report_generated', bytes: report.bytesize)
      raise ArgumentError, 'Validation report exceeds storage limit' if report.bytesize >= 16.megabytes
      attributes = { report_csv: report, completed_at: Time.current,
        validation_status: failures.positive? ? 'completed_with_issues' : 'completed',
        validation_error: nil }
    rescue StandardError => e
      log_exception('processing_failed', e)
      attributes = { validation_status: 'failed', completed_at: Time.current,
        validation_error: 'The authority check failed. No usable report could be produced. Your uploaded headings remain available. Please retry.' }
    end
    # Never attach old results to a replacement inventory or a newer attempt.
    scope = SubjectHeadingInventory.where(id: inventory_id, validation_token: token, validation_status: 'running', updated_at: claim_stamp)
    begin
      updated = scope.update_all(attributes)
      log_event('final_state_write', updated: updated, status: attributes[:validation_status])
    rescue ActiveRecord::StatementInvalid => e
      log_exception('report_storage_failed', e)
      # A report-storage failure must not strand a usable inventory in running.
      updated = scope.update_all(validation_status: 'failed', completed_at: Time.current,
        validation_error: 'The authority check report could not be saved. Uploaded headings remain available. Please retry.')
      log_event('failure_state_write', updated: updated)
    end
    notify(inventory, token, requester) if updated == 1
  end

  def notify(inventory, token, requester)
    inventory.reload.with_lock do
      unless inventory.validation_token == token && inventory.notified_at.nil?
        log_event('notification_skipped', already_notified: inventory.notified_at.present?)
        return
      end
      log_event('notification_started')
      UserMailer.subject_heading_validation_finished(inventory, recipient: requester).deliver_now
      inventory.update!(notified_at: Time.current)
      log_event('notification_finished')
    end
  rescue ActiveRecord::RecordNotFound
    log_event('notification_inventory_replaced')
  end

  def log_event(event, **data)
    @validation_logger.info("LC_AUTHORITY #{event} #{data.to_json}")
  end

  def log_exception(event, error)
    @validation_logger.error("LC_AUTHORITY #{event} #{ { error_class: error.class.name, error: error.message, backtrace: error.backtrace }.to_json}")
  end
end
