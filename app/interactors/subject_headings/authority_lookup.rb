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

  TYPES = { 'subjects' => 'Subject', 'names' => 'Name', 'genreForms' => 'Genre/form' }.freeze
  MADS = 'http://www.loc.gov/mads/rdf/v1#'.freeze

  def self.normalize(label)
    label.to_s.gsub(/[[:space:]]+/, ' ').strip.sub(/\.\z/, '').gsub(/(?<=[[:alpha:]][[:alpha:]])\.(?=[[:alpha:]])/, '. ')
  end

  def call(heading, identifier: nil)
    key = Digest::SHA256.hexdigest([heading, identifier].to_json)
    @cache.fetch("subject-headings/loc/v2/#{key}", expires_in: 7.days) do
      supplied = authority(identifier) if authority_uri(identifier)
      if supplied && equivalent?(heading, supplied)
        next [supplied]
      end
      supplied = supplied.merge('identifier_mismatch' => true) if supplied
      candidates = search(heading, 'leftanchored')
      verified = verify_candidates(heading, candidates)
      next (verified + [supplied]).compact if verified.any? { |hit| hit['aLabel'] == heading }
      normalized = self.class.normalize(heading)
      if normalized != heading
        candidates += search(normalized, 'leftanchored')
        verified += verify_candidates(heading, candidates)
      end
      if verified.any? { |hit| self.class.normalize(hit['aLabel']) == normalized }
        next (verified + [supplied]).compact.uniq { |hit| hit['uri'] }
      end
      verified += candidates.map { |hit| authority(hit['uri']) }
      next (verified + [supplied]).compact.uniq { |hit| hit['uri'] } if verified.any? { |hit| equivalent?(heading, hit) }
      candidates += search(heading, 'keyword')
      verified += verify_candidates(heading, candidates)
      (verified + [supplied].compact + candidates.map { |hit| hit.merge('evidence' => 'keyword') }).uniq { |hit| hit['uri'] }
    end
  end

  private

  def equivalent?(heading, hit)
    self.class.normalize(hit['aLabel']) == self.class.normalize(heading) ||
      hit.fetch('variants', []).any? { |label| self.class.normalize(label) == self.class.normalize(heading) }
  end

  def authority_uri(value)
    match = value.to_s.match(%r{\Ahttps?://id\.loc\.gov/authorities/(subjects|names|genreForms)/([A-Za-z0-9_-]+)(?:\.html)?/?(?:\#.*)?\z})
    "https://id.loc.gov/authorities/#{match[1]}/#{match[2]}" if match
  end

  def authority(value)
    canonical = authority_uri(value)
    raise LookupError, 'Unsupported LC authority identifier' unless canonical
    @cache.fetch("subject-headings/record/v2/#{Digest::SHA256.hexdigest(canonical)}", expires_in: 7.days) do
      data = request_json(URI("#{canonical}.madsrdf_raw.jsonld"), 'authority')
      graph = data.is_a?(Hash) ? data['@graph'] : data
      raise LookupError, 'Authority response could not be processed.' unless graph.is_a?(Array) && graph.all? { |node| node.is_a?(Hash) }
      root = graph.find { |node| authority_uri(node['@id']) == canonical }
      labels = values(root, 'authoritativeLabel')
      raise LookupError, 'Authority response could not be processed.' unless labels.one? && labels.first.is_a?(String)
      variants = Array(root["#{MADS}hasVariant"]).flat_map do |link|
        node = graph.find { |entry| entry['@id'] == link['@id'] } if link.is_a?(Hash)
        values(node, 'variantLabel')
      end
      { 'aLabel' => labels.first, 'uri' => canonical, 'variants' => variants,
        'authority_type' => TYPES.fetch(canonical.split('/')[4]), 'evidence' => 'authority' }
    end
  end

  def values(node, predicate)
    Array(node && node["#{MADS}#{predicate}"]).filter_map { |value| value['@value'] if value.is_a?(Hash) }
  end

  def search(heading, searchtype)
    SOURCES.flat_map do |source|
      uri = URI("https://id.loc.gov/authorities/#{source}/suggest2/")
      uri.query = URI.encode_www_form(q: heading, count: 20, searchtype: searchtype)
      data = request_json(uri, source)
      unless data.is_a?(Hash) && data['hits'].is_a?(Array) && data['count'].is_a?(Numeric)
        raise LookupError, 'Authority response could not be processed.'
      end
      data['hits'].map do |hit|
        raise LookupError, 'Authority response could not be processed.' unless hit.is_a?(Hash) && authority_uri(hit['uri'])
        hit.slice('aLabel', 'suggestLabel').merge('uri' => authority_uri(hit['uri']))
      end
    end.uniq { |hit| hit['uri'] }
  end

  def verify_candidates(heading, hits)
    hits.select do |hit|
      !hit['aLabel'].is_a?(String) || self.class.normalize(hit['aLabel']) == self.class.normalize(heading) ||
        self.class.normalize(hit['suggestLabel']) == self.class.normalize(heading)
    end.map { |hit| authority(hit['uri']) }
  end

  def request_json(uri, source)
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
      JSON.parse(response.body)
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
      raise LookupError, 'Authority response could not be processed.' if e.is_a?(JSON::ParserError)
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
