require 'csv'

class SubjectHeadingInventory < ApplicationRecord
  belongs_to :transcription_field
  has_many :subject_headings, dependent: :delete_all
  serialize :source_rows, coder: JSON

  def log_file
    SubjectHeadings::ValidationLog.path(id)
  end

  CLAIM_TIMEOUT = 10.minutes

  def validation_retryable?
    %w[failed not_requested completed completed_with_issues].include?(validation_status) ||
      (validation_status == 'running' && updated_at < CLAIM_TIMEOUT.ago)
  end

  STATUSES = %w[not_requested queued running completed completed_with_issues failed].freeze
  validates :validation_status, inclusion: { in: STATUSES }

  def authority_check_counts
    return nil if report_csv.blank?
    report = CSV.parse(report_csv.delete_prefix("\uFEFF"), headers: true)
    return nil unless report.headers&.include?('result')
    failed = report.count { |row| row['result'] == 'lookup_error' }
    unattempted = report.count { |row| row['result'] == 'not_checked' }
    exact = report.count { |row| row['result'] == 'exact_match' }
    successful = report.size - failed - unattempted
    { total: report.size, successful: successful, exact: exact, review: successful - exact, failed: failed, unattempted: unattempted }
  rescue CSV::MalformedCSVError
    nil
  end

  def authority_check_outcome
    counts = authority_check_counts
    if validation_status == 'failed' && counts && counts[:failed] + counts[:unattempted] > 0
      'completed_with_issues'
    else
      validation_status
    end
  end

  def authority_check_title
    if authority_check_outcome == 'completed_with_issues'
      counts = authority_check_counts
      return 'Authority check completed with issues' unless counts
      if counts[:failed].positive?
        "Authority check completed with #{counts[:failed]} lookup #{counts[:failed] == 1 ? 'error' : 'errors'}"
      else
        "Authority check completed with #{counts[:unattempted]} unchecked #{counts[:unattempted] == 1 ? 'heading' : 'headings'}"
      end
    else
      "Authority check: #{authority_check_outcome.humanize}"
    end
  end

  def authority_check_summary
    counts = authority_check_counts
    return nil unless counts
    parts = ["#{counts[:exact]} exact-label #{counts[:exact] == 1 ? 'match' : 'matches'}"]
    parts << "#{counts[:review]} other #{counts[:review] == 1 ? 'result' : 'results'} for review" if counts[:review].positive?
    parts << "#{counts[:failed]} lookup #{counts[:failed] == 1 ? 'error' : 'errors'}" if counts[:failed].positive?
    parts << "#{counts[:unattempted]} #{counts[:unattempted] == 1 ? 'heading' : 'headings'} not checked" if counts[:unattempted].positive?
    parts.join(' · ')
  end

  def queue_validation!(user: Current.user || transcription_field.collection.owner)
    with_lock do
      return false unless validation_retryable?
      update!(validation_status: 'queued', validation_token: SecureRandom.uuid,
              report_csv: nil, validation_error: nil, completed_at: nil, notified_at: nil)
    end
    job = SubjectHeadings::ValidateJob.perform_later(user_id: user.id, inventory_id: id, token: validation_token)
    raise ActiveJob::EnqueueError, 'Validation enqueue failed' unless job
    job
  rescue ActiveJob::EnqueueError
    update!(validation_status: 'failed', validation_error: 'The authority check could not be queued. Uploaded headings remain available. Please retry.')
  end
end
