# :nocov:
class Workers::Base < ApplicationInteractor
  def notifier
    @notifier ||= Slack::Notifier.new(
      Settings.slack_webhook.url,
      channel: Settings.slack_webhook.channel,
      username: Settings.slack_webhook.username
    )
  end
end
# :nocov:
