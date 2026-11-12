class SubjectHeadings::ValidateJob < ApplicationJob
  queue_as :subject_headings

  def perform(user_id:, validation_id:, token:)
    path = SubjectHeadings::ValidationLog.path
    Rails.logger.info("LC_AUTHORITY job_log #{ { validation_id: validation_id, job_id: job_id, path: path.to_s }.to_json}")
    SubjectHeadings::ValidationLog.open(validation_id: validation_id, job_id: job_id, token: token) do |logger|
      @validation_logger = logger
      log_event('execution_started', user_id: user_id)
      begin
        validate(user_id: user_id, validation_id: validation_id, token: token)
      rescue StandardError => e
        log_exception('execution_failed', e)
        raise
      ensure
        log_event('execution_ended')
      end
    end
  end

  private

  def validate(user_id:, validation_id:, token:)
    validation = SubjectHeadingValidation.find_by(id: validation_id, token: token)
    unless validation
      log_event('obsolete_validation_or_token')
      return
    end
    requester = User.find_by(id: user_id)
    unless requester && (requester.admin? || requester.like_owner?(validation.transcription_field.collection))
      log_event('requester_no_longer_authorized', user_id: user_id)
      SubjectHeadingValidation.where(id: validation_id, token: token, status: 'queued')
        .update_all(status: 'failed', completed_at: Time.current,
          error_message: 'The requester no longer has project access. Please validate the file again.')
      return
    end
    if validation.finished?
      log_event('already_finalized', status: validation.status)
      notify(validation, token, requester)
      return
    end
    # Compare-and-set prevents two deliveries from validating the same upload.
    claim_stamp = Time.current
    attempts = SubjectHeadingValidation.where(id: validation_id, token: token)
    claimable = attempts.where(status: 'queued').or(
      attempts.where(status: 'running').where('updated_at < ?', SubjectHeadingValidation::CLAIM_TIMEOUT.ago)
    )
    claimed = claimable.update_all(status: 'running', updated_at: claim_stamp)
    log_event('claim_result', claimed: claimed, previous_status: validation.status)
    return unless claimed == 1

    begin
      heartbeat = lambda do
        next_stamp = Time.current
        owned = attempts.where(status: 'running', updated_at: claim_stamp).update_all(updated_at: next_stamp)
        raise SubjectHeadings::AuthorityLookup::LookupError, 'Validation attempt is no longer current.' unless owned == 1
        claim_stamp = next_stamp
        log_event('lease_renewed', row: @row_index, at: claim_stamp.iso8601(6))
      end
      lookup = SubjectHeadings::AuthorityLookup.new(heartbeat: heartbeat, logger: @validation_logger)
      failures = 0
      consecutive_failures = 0
      skipped = 0
      memo = {}
      processed = 0
      # A retry rechecks only the lookup errors and unchecked headings of the previous report.
      retrying = validation.report_csv.present?
      rows = retrying ? validation.report_rows : validation.source_rows
      log_event('processing_started', total_rows: rows.size, retrying: retrying)
      results = rows.each_with_index.map do |row, index|
        @row_index = index + 1
        next row if retrying && !SubjectHeadingValidation::ERROR_RESULTS.include?(row['result'])

        row = row.slice('heading', 'uri')
        log_event('row_started', row: @row_index, total_rows: rows.size, heading: row['heading'], uri: row['uri'])
        # Replacing the validation deletes this record; stop spending requests immediately.
        next_stamp = Time.current
        owned = attempts.where(status: 'running', updated_at: claim_stamp)
          .update_all(updated_at: next_stamp, processed_count: processed)
        unless owned == 1
          log_event('ownership_lost', row: @row_index)
          return
        end
        processed += 1
        claim_stamp = next_stamp
        begin
          memo_key = [row['heading'], row['uri']]
          if consecutive_failures >= 3 && !memo.key?(memo_key)
            skipped += 1
            log_event('row_not_checked', row: @row_index, skipped: skipped, failures: failures)
            next row.merge('result' => 'not_checked', 'rationale' => 'No request made: further lookups stopped after three consecutive failed heading lookups. Please retry lookup errors later.')
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
      issues = results.any? { |row| SubjectHeadingValidation::ERROR_RESULTS.include?(row['result']) }
      attributes = { report_csv: report, completed_at: Time.current, processed_count: processed,
        status: issues ? 'completed_with_issues' : 'completed',
        error_message: nil }
    rescue StandardError => e
      log_exception('processing_failed', e)
      attributes = { status: 'failed', completed_at: Time.current,
        error_message: 'Validation failed and no report could be produced. Please try again.' }
    end
    # Never attach old results to a replacement validation or a newer attempt.
    scope = SubjectHeadingValidation.where(id: validation_id, token: token, status: 'running', updated_at: claim_stamp)
    begin
      updated = scope.update_all(attributes)
      log_event('final_state_write', updated: updated, status: attributes[:status])
    rescue ActiveRecord::StatementInvalid => e
      log_exception('report_storage_failed', e)
      # A report-storage failure must not strand the validation in running.
      updated = scope.update_all(status: 'failed', completed_at: Time.current,
        error_message: 'The validation report could not be saved. Please try again.')
      log_event('failure_state_write', updated: updated)
    end
    notify(validation, token, requester) if updated == 1
  end

  def notify(validation, token, requester)
    validation.reload.with_lock do
      unless validation.token == token && validation.notified_at.nil?
        log_event('notification_skipped', already_notified: validation.notified_at.present?)
        return
      end
      log_event('notification_started')
      UserMailer.subject_heading_validation_finished(validation, recipient: requester).deliver_now
      validation.update!(notified_at: Time.current)
      log_event('notification_finished')
    end
  rescue ActiveRecord::RecordNotFound
    log_event('notification_validation_replaced')
  end

  def log_event(event, **data)
    @validation_logger.info("LC_AUTHORITY #{event} #{data.to_json}")
  end

  def log_exception(event, error)
    @validation_logger.error("LC_AUTHORITY #{event} #{ { error_class: error.class.name, error: error.message, backtrace: error.backtrace }.to_json}")
  end
end
