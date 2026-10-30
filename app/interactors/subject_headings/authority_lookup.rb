require 'net/http'
require 'digest'

class SubjectHeadings::AuthorityLookup
  class LookupError < StandardError; end
  class TransientError < LookupError; end
  SOURCES = %w[subjects names genreForms].freeze

  # LC's Suggest2 contract: hits[].aLabel, suggestLabel, uri.
  # See doc/subject_headings.md for documentation and primary client references.
  def initialize(cache: Rails.cache, sleeper: ->(seconds) { sleep seconds })
    @cache, @sleeper = cache, sleeper
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
      @sleeper.call(0.25) # sequential, at most four uncached requests/second
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10
      http.write_timeout = 5
      http.max_retries = 0
      response = http.get(uri.request_uri, 'Accept' => 'application/json', 'User-Agent' => 'FromThePage-SubjectHeadings/1.0')
      raise TransientError, "LC returned HTTP #{response.code}" if response.code == '429' || response.code.to_i >= 500
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
        @sleeper.call(0.5 * (2**(attempts - 1)))
        retry
      end
      raise LookupError, "LC lookup failed after #{attempts} attempts (#{e.class.name.demodulize})"
    rescue JSON::ParserError, OpenSSL::SSL::SSLError => e
      raise LookupError, "LC lookup failed (#{e.class.name.demodulize})"
    end
  end
end
