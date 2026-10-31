class SubjectHeadings::ValidateJob < ApplicationJob
  queue_as :subject_headings

  def perform(user_id:, inventory_id:, token:)
    inventory = SubjectHeadingInventory.find_by(id: inventory_id, validation_token: token)
    return unless inventory
    requester = User.find_by(id: user_id)
    unless requester && (requester.admin? || requester.like_owner?(inventory.transcription_field.collection))
      SubjectHeadingInventory.where(id: inventory_id, validation_token: token, validation_status: 'queued')
        .update_all(validation_status: 'failed', completed_at: Time.current,
          validation_error: 'The requester no longer has project access. Please retry the authority check.')
      return
    end
    if %w[completed failed].include?(inventory.validation_status)
      notify(inventory, token)
      return
    end
    # Compare-and-set prevents two deliveries from validating the same upload.
    claim_stamp = Time.current
    attempts = SubjectHeadingInventory.where(id: inventory_id, validation_token: token)
    claimable = attempts.where(validation_status: 'queued').or(
      attempts.where(validation_status: 'running').where('updated_at < ?', SubjectHeadingInventory::CLAIM_TIMEOUT.ago)
    )
    claimed = claimable.update_all(validation_status: 'running', updated_at: claim_stamp)
    return unless claimed == 1

    begin
      heartbeat = lambda do
        next_stamp = Time.current
        owned = attempts.where(validation_status: 'running', updated_at: claim_stamp).update_all(updated_at: next_stamp)
        raise SubjectHeadings::AuthorityLookup::LookupError, 'Validation attempt is no longer current.' unless owned == 1
        claim_stamp = next_stamp
      end
      lookup = SubjectHeadings::AuthorityLookup.new(heartbeat: heartbeat)
      failures = 0
      consecutive_failures = 0
      skipped = 0
      memo = {}
      results = inventory.source_rows.map do |row|
        # A replacement deletes this import; stop spending requests immediately.
        next_stamp = Time.current
        owned = attempts.where(validation_status: 'running', updated_at: claim_stamp)
          .update_all(updated_at: next_stamp)
        return unless owned == 1
        claim_stamp = next_stamp
        begin
          if consecutive_failures >= 3 && !memo.key?(row['heading'])
            skipped += 1
            next row.merge('result' => 'not_checked', 'rationale' => 'No request made: further lookups stopped after three consecutive failed heading lookups. Please retry the authority check later.')
          end
          hits = memo[row['heading']] ||= lookup.call(row['heading'])
          consecutive_failures = 0
          SubjectHeadings::Report.result(row, hits)
        rescue SubjectHeadings::AuthorityLookup::LookupError => e
          failures += 1
          consecutive_failures += 1
          row.merge('result' => 'lookup_error', 'rationale' => e.message)
        end
      end
      report = SubjectHeadings::Report.generate(results)
      raise ArgumentError, 'Validation report exceeds storage limit' if report.bytesize >= 16.megabytes
      attributes = { report_csv: report, completed_at: Time.current,
        validation_status: failures.positive? ? 'failed' : 'completed',
        validation_error: failures.positive? ? "#{failures} heading lookups failed; #{skipped} headings were not checked after requests stopped. Download the partial report or retry. Uploaded headings remain available." : nil }
    rescue StandardError => e
      Rails.logger.error("Subject heading validation #{inventory_id} failed: #{e.class}")
      attributes = { validation_status: 'failed', completed_at: Time.current,
        validation_error: 'Validation could not be completed. The uploaded inventory remains available. Please retry.' }
    end
    # Never attach old results to a replacement inventory or a newer attempt.
    scope = SubjectHeadingInventory.where(id: inventory_id, validation_token: token, validation_status: 'running', updated_at: claim_stamp)
    begin
      updated = scope.update_all(attributes)
    rescue ActiveRecord::StatementInvalid
      # A report-storage failure must not strand a usable inventory in running.
      updated = scope.update_all(validation_status: 'failed', completed_at: Time.current,
        validation_error: 'The validation report could not be saved. Uploaded headings remain available. Please retry.')
    end
    notify(inventory, token) if updated == 1
  end

  private

  def notify(inventory, token)
    inventory.reload.with_lock do
      return unless inventory.validation_token == token && inventory.notified_at.nil?
      UserMailer.subject_heading_validation_finished(inventory).deliver_now
      inventory.update!(notified_at: Time.current)
    end
  rescue ActiveRecord::RecordNotFound
    # Inventory was replaced while validation was finishing.
  end
end
