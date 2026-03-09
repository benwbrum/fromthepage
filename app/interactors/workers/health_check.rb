# :nocov:
class Workers::HealthCheck < ApplicationInteractor
  STALE_SECONDS = 120
  JOB_THRESHOLD = 1_000

  def initialize
    super
  end

  def perform
    return unless alert_needed?

    notifier.ping(message)
  end

  private

  def alert_needed?
    queue_alert = pending.values.any? { |count| count >= JOB_THRESHOLD }
    no_workers = workers.count.zero?
    stale_alert = stale_workers.any?

    queue_alert || no_workers || stale_alert
  end

  def notifier
    @notifier ||= Slack::Notifier.new(
      Settings.slack_webhook.url,
      channel: Settings.slack_webhook.channel,
      username: Settings.slack_webhook.username
    )
  end

  def message
    status_emoji = stale_workers.any? || workers.count.zero? ? '🔴' : '🟢'

    lines = []

    timestamp_line = "========== #{Time.current.strftime("%Y-%m-%d %H:%M:%S %Z")} =========="
    lines << timestamp_line
    lines << "#{status_emoji} SolidQueue Health Check"
    lines << "RAILS_ENV=#{Rails.env} | <!channel>"
    lines << ''
    lines << "Workers: #{workers.count}"
    lines << "Stale: #{stale_workers.count}"
    lines << ''

    lines << 'Queues:'
    pending.each do |queue, count|
      warn = count >= JOB_THRESHOLD ? ' ⚠' : ''
      lines << "- #{queue}: #{count}#{warn}"
    end

    lines << ''
    lines << 'Workers:'

    workers.each do |w|
      queue = w.metadata['queues']

      stale = w.last_heartbeat_at < STALE_SECONDS.seconds.ago ? ' (STALE)' : ''

      heartbeat =
        if w.last_heartbeat_at
          w.last_heartbeat_at.strftime('%H:%M:%S')
        else
          'nil'
        end

      lines << "- #{w.hostname} / #{queue} / pid #{w.pid} / hb #{heartbeat}#{stale}"
    end

    lines << '=' * timestamp_line.delete(' ').length

    lines.join("\n")
  end

  def workers
    @workers ||= SolidQueue::Process.where(kind: 'Worker')
  end

  def pending
    @pending ||= SolidQueue::Job.where(finished_at: nil).group(:queue_name).count
  end

  def stale_workers
    @stale_workers ||= workers.select do |w|
      w.last_heartbeat_at && w.last_heartbeat_at < STALE_SECONDS.seconds.ago
    end
  end
end
# :nocov:
