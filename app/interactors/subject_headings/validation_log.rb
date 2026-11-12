require 'time'

class SubjectHeadings::ValidationLog
  # All validations share one append-only file; each line carries the
  # validation ID, job ID and token so a single run can be filtered out.
  def self.path
    Rails.root.join('log', 'subject_headings.log')
  end

  def self.open(validation_id:, job_id:, token:)
    logger = ActiveSupport::Logger.new(path)
    logger.level = Rails.logger.level
    context = { validation_id: validation_id, job_id: job_id, token: token }.to_json
    logger.formatter = proc do |severity, time, _name, message|
      "#{time.utc.iso8601(6)} #{severity} #{context} #{message}\n"
    end
    yield logger
  ensure
    logger&.close
  end
end
