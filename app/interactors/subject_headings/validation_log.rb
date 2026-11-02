require 'fileutils'
require 'time'

class SubjectHeadings::ValidationLog
  def self.path(inventory_id)
    Rails.root.join('log', 'subject_headings', "inventory_#{Integer(inventory_id)}.log")
  end

  def self.open(inventory_id:, job_id:, token:)
    file = path(inventory_id)
    FileUtils.mkdir_p(file.dirname)
    logger = ActiveSupport::Logger.new(file)
    logger.level = Rails.logger.level
    context = { inventory_id: inventory_id, job_id: job_id, token: token }.to_json
    logger.formatter = proc do |severity, time, _name, message|
      "#{time.utc.iso8601(6)} #{severity} #{context} #{message}\n"
    end
    yield logger
  ensure
    logger&.close
  end
end
