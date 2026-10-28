# Tags New Relic transactions (and Browser PageViews when configured) with
# a few attributes that let us separate real-user experience from crawler
# traffic in NRQL, e.g.
#
#   SELECT percentile(duration, 95) FROM Transaction WHERE request_kind = 'human'
#
# Attributes are only recorded when the agent is loaded.
module NewRelicRequestAttributes
  extend ActiveSupport::Concern

  # ~67% of production requests come from a headless fleet that rotates Chrome
  # versions but always reports this exact macOS platform string.
  SUSPECT_UA_FRAGMENT = 'Macintosh; Intel Mac OS X 10_15_7'.freeze

  private

  def record_new_relic_request_attributes
    return unless defined?(::NewRelic::Agent)

    ::NewRelic::Agent.add_custom_attributes(new_relic_request_attributes)
  rescue StandardError => e
    Rails.logger.warn { "Skipping New Relic request attributes: #{e.class}" }
  end

  def new_relic_request_attributes
    signed_in = respond_to?(:user_signed_in?, true) && user_signed_in?

    {
      request_kind: new_relic_request_kind(signed_in),
      logged_in: signed_in,
      owner: signed_in && current_user.owner ? true : false,
      has_session_cookie: session_cookie_present?,
      collection_slug: @collection&.slug
    }.compact
  end

  def session_cookie_present?
    request.cookie_jar.key?(Rails.application.config.session_options[:key].to_s)
  end

  # 'bot' for self-declared crawlers, 'suspect' for the anonymous macOS Chrome
  # fingerprint fleet, 'human' for everything else.
  def new_relic_request_kind(signed_in)
    return 'human' if signed_in

    ua = request.user_agent.to_s
    return 'bot' if browser.bot?
    return 'suspect' if ua.include?(SUSPECT_UA_FRAGMENT) && !session_cookie_present?

    'human'
  end
end
