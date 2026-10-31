require 'net/http'
require 'digest'
require 'time'

class SubjectHeadings::AuthorityLookup
  class LookupError < StandardError; end
  class TransientError < LookupError
    attr_reader :retry_after, :status

    def initialize(message, retry_after: nil, status: nil)
      super(message)
      @retry_after, @status = retry_after, status
    end
  end
  SOURCES = %w[subjects names genreForms].freeze

  # LC's Suggest2 contract: hits[].aLabel, suggestLabel, uri.
  # See doc/subject_headings.md for documentation and primary client references.
  def initialize(cache: Rails.cache, sleeper: ->(seconds) { sleep seconds }, logger: Rails.logger, heartbeat: nil)
    @cache, @sleeper, @logger, @heartbeat = cache, sleeper, logger, heartbeat
  end

  def call(heading)
    @cache.fetch("subject-headings/loc/v1/#{Digest::SHA256.hexdigest(heading)}", expires_in: 7.days) do
      SOURCES.flat_map { |source| lookup(source, heading) }.uniq { |hit| hit['uri'] }
    end
  end

  private

  def lookup(source, heading)
    uri = URI("https://id.loc.gov/authorities/#{source}/suggest2/")
    uri.query = URI.encode_www_form(q: heading, count: 5, searchtype: 'keyword')
    attempts = 0
    begin
      attempts += 1
      @heartbeat&.call
      @sleeper.call(0.25) # sequential, at most four uncached requests/second
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10
      http.write_timeout = 5
      http.max_retries = 0
      @logger.info("[LC authority] request #{ { url: uri.to_s, attempt: attempts }.to_json}")
      response = http.get(uri.request_uri, 'Accept' => 'application/json', 'User-Agent' => 'FromThePage-SubjectHeadings/1.0')
      @logger.info("[LC authority] response #{ { source: source, status: response.code, retry_after: response['Retry-After'], content_type: response['Content-Type'] }.to_json}")
      @logger.debug { "[LC authority] response body #{response.body.to_s.byteslice(0, 4096).to_s.force_encoding(Encoding::UTF_8).scrub.to_json}" }
      if response.code == '429' || response.code.to_i >= 500
        raise TransientError.new("LC returned HTTP #{response.code}", retry_after: retry_after_seconds(response['Retry-After']), status: response.code)
      end
      raise LookupError, "LC returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      unless data.is_a?(Hash) && data['hits'].is_a?(Array) && data['count'].is_a?(Numeric)
        raise LookupError, 'Unexpected LC response format'
      end
      data['hits'].map do |hit|
        unless hit.is_a?(Hash) && hit['aLabel'].is_a?(String) && hit['aLabel'].present? &&
          hit['uri'].is_a?(String) && hit['uri'].match?(%r{\Ahttps?://id\.loc\.gov/authorities/(subjects|names|genreForms)/[A-Za-z0-9]+\z})
          raise LookupError, 'Unexpected LC authority record'
        end
        hit.slice('aLabel', 'suggestLabel', 'uri')
      end
    rescue TransientError, Timeout::Error, IOError, SocketError, SystemCallError => e
      if attempts < 3
        base = e.is_a?(TransientError) && %w[429 503].include?(e.status) ? 30 : 2
        delay = [base * (2**(attempts - 1)), e.is_a?(TransientError) ? e.retry_after.to_f : 0].max
        @logger.warn("[LC authority] retry #{ { source: source, attempt: attempts, error: e.message, delay_seconds: delay }.to_json}")
        wait(delay)
        retry
      end
      @logger.error("[LC authority] failed #{ { source: source, attempts: attempts, error_class: e.class.name, error: e.message }.to_json}")
      raise LookupError, "LC #{source} request failed after #{attempts} attempts: #{e.message} (#{e.class.name.demodulize})"
    rescue JSON::ParserError, OpenSSL::SSL::SSLError => e
      @logger.error("[LC authority] failed #{ { source: source, error_class: e.class.name }.to_json}")
      raise LookupError, "LC #{source} request failed (#{e.class.name.demodulize})"
    end
  end

  def retry_after_seconds(value)
    return nil if value.blank?
    return value.to_i if value.match?(/\A\d+\z/)
    [Time.httpdate(value) - Time.now, 0].max
  rescue ArgumentError
    nil
  end

  def wait(seconds)
    return @sleeper.call(seconds) unless @heartbeat
    while seconds.positive?
      @heartbeat.call
      interval = [seconds, 30].min
      @sleeper.call(interval)
      seconds -= interval
    end
    @heartbeat.call
  end
end
