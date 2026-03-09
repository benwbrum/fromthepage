# :nocov:
class Workers::HealthCheck < ApplicationInteractor
  STALE_SECONDS = 120
  WARN_ON_QUEUE_COUNT = 1_000

  def initialize
    super
  end

  def perform
    notifier.ping(message)
  end

  private

  def notifier
    @notifier ||= Slack::Notifier.new(
      Settings.slack_webhook.url,
      channel: Settings.slack_webhook.channel,
      username: Settings.slack_webhook.username
    )
  end

  def message
    workers = SolidQueue::Process.where(kind: 'Worker')
    pending = SolidQueue::Job.where(finished_at: nil).group(:queue_name).count

    stale_workers = workers.select do |w|
      w.last_heartbeat_at < STALE_SECONDS.seconds.ago
    end
    status_emoji = stale_workers.any? || workers.count.zero? ? '🔴' : '🟢'

    lines = []

    lines << "========== #{Time.current.strftime("%Y-%m-%d %H:%M:%S %Z")} =========="
    lines << "#{status_emoji} SolidQueue Health Check"
    lines << ''
    lines << "Workers: #{workers.count}"
    lines << "Stale: #{stale_workers.count}"
    lines << ''

    lines << 'Queues:'
    pending.each do |queue, count|
      warn = count >= WARN_ON_QUEUE_COUNT ? ' ⚠' : ''
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

    lines.join("\n")
  end
end
# :nocov:
