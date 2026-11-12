require 'csv'

# An optional, advisory check of a subject headings file for duplicates and against
# Library of Congress authority records. It never saves headings to the field.
class SubjectHeadingValidation < ApplicationRecord
  belongs_to :transcription_field
  serialize :source_rows, coder: JSON

  STATUSES = %w[queued running completed completed_with_issues failed].freeze
  FINISHED_STATUSES = %w[completed completed_with_issues failed].freeze
  ERROR_RESULTS = %w[lookup_error not_checked].freeze
  CLAIM_TIMEOUT = 10.minutes

  validates :status, inclusion: { in: STATUSES }

  # Parses the upload, merges duplicate rows, replaces any earlier validation for
  # the field and queues the background check. Raises Import::ImportError on bad files.
  def self.start!(field:, upload:, user:)
    rows = SubjectHeadings::Import.parse(upload)
    unique = SubjectHeadings::Import.unique(rows)
    validation = field.with_lock do
      field.subject_heading_validation&.destroy!
      field.create_subject_heading_validation!(
        filename: SubjectHeadings::Import.filename(upload), row_count: rows.size,
        source_rows: unique, total_count: unique.size, status: 'queued', token: SecureRandom.uuid
      )
    end
    validation.send(:enqueue!, user)
    validation
  end

  def in_progress?
    %w[queued running].include?(status)
  end

  def finished?
    FINISHED_STATUSES.include?(status)
  end

  def stalled?
    status == 'running' && updated_at < CLAIM_TIMEOUT.ago
  end

  # A finished check can be retried when it left lookup errors or produced no report;
  # a stalled one can always be recovered.
  def retryable?
    stalled? || (finished? && (report_csv.blank? || lookup_errors?))
  end

  def progress_percent
    return 0 if total_count.zero?
    [(processed_count * 100) / total_count, 99].min
  end

  def unique_count
    source_rows.size
  end

  def duplicate_count
    row_count - unique_count
  end

  # Report rows with spreadsheet escaping reversed, ready to feed back into Report.generate.
  def report_rows
    return [] if report_csv.blank?
    CSV.parse(report_csv.delete_prefix("\uFEFF"), headers: true).map do |row|
      row.to_h.transform_values { |value| SubjectHeadings::Report.import_cell(value) }
    end
  rescue CSV::MalformedCSVError
    []
  end

  def counts
    return nil if report_csv.blank?
    rows = report_rows
    return nil if rows.empty? || !rows.first.key?('result')
    exact = rows.count { |row| row['result'] == 'exact_match' }
    errors = rows.count { |row| ERROR_RESULTS.include?(row['result']) }
    { total: rows.size, exact: exact, possible: rows.size - exact - errors, errors: errors }
  end

  def badge_count
    counts ? counts[:possible] + counts[:errors] : 0
  end

  def lookup_errors?
    counts.present? && counts[:errors].positive?
  end

  # Re-runs the check. When a report exists, only lookup errors and unchecked headings are
  # retried; otherwise the whole file is checked again. Returns false if not retryable.
  def queue!(user:)
    with_lock do
      return false unless retryable?
      update!(status: 'queued', token: SecureRandom.uuid, processed_count: 0,
              total_count: report_csv.present? ? counts.to_h.fetch(:errors, 0) : unique_count,
              error_message: nil, completed_at: nil, notified_at: nil)
    end
    enqueue!(user)
  end

  private

  def enqueue!(user)
    job = SubjectHeadings::ValidateJob.perform_later(user_id: user.id, validation_id: id, token: token)
    raise ActiveJob::EnqueueError, 'Validation enqueue failed' unless job
    job
  rescue ActiveJob::EnqueueError
    update!(status: 'failed', completed_at: Time.current, error_message: 'Validation could not be started. Please try again.')
    false
  end
end
