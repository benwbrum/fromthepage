# :nocov:
class Workers::EnvCheck < Workers::Base
  REQUIRED_VARS = [
    'LINODE_ENDPOINT',
    'LINODE_ACCESS_KEY_ID',
    'LINODE_SECRET_ACCESS_KEY',
    'LINODE_BUCKET',
    'GEMINI_API_KEY',
    'ELASTIC_CLOUD_ID',
    'ELASTIC_API_KEY'
  ].freeze

  def initialize
    super
  end

  def perform
    missing = missing_vars
    return if missing.empty?

    notifier.ping(message(missing))
  end

  private

  def missing_vars
    REQUIRED_VARS.select { |key| ENV[key].nil? || ENV[key].strip.empty? }
  end

  def message(missing)
    timestamp_line = "========== #{Time.current.strftime("%Y-%m-%d %H:%M:%S %Z")} =========="

    lines = []
    lines << timestamp_line
    lines << '🔴 SolidQueue Environment Check Failed'
    lines << "RAILS_ENV=#{Rails.env} | <!channel>"
    lines << ''
    lines << "Missing ENV vars (#{missing.count}):"

    missing.each do |key|
      lines << "- #{key}"
    end

    lines << ''
    lines << '=========='

    lines.join("\n")
  end
end
# :nocov:
