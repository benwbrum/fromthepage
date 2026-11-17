require 'open-uri'

# Fetches IIIF resources, retrying the transient failures some IIIF servers
# (notably iiif.archive.org) return under load.
module IiifHttp
  ATTEMPTS = 3
  RETRY_DELAY = 1 # seconds, multiplied by the attempt number

  OPTIONS = {
    'Accept-Encoding' => 'identity', # Disable compression to avoid inflater path
    'User-Agent' => 'FromThePage-IIIF/1.0',
    'Connection' => 'close',
    open_timeout: 10,
    read_timeout: 20,
    ssl_verify_mode: OpenSSL::SSL::VERIFY_PEER
  }.freeze

  TRANSIENT_ERRORS = [
    OpenSSL::SSL::SSLError,
    EOFError,
    Errno::ECONNRESET,
    Net::OpenTimeout,
    Net::ReadTimeout,
    OpenURI::HTTPError
  ].freeze

  def self.fetch(url)
    # Set OpenSSL flag to ignore unexpected EOF (for OpenSSL 3.0 compatibility)
    if OpenSSL::SSL.const_defined?(:OP_IGNORE_UNEXPECTED_EOF)
      OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:options] |= OpenSSL::SSL::OP_IGNORE_UNEXPECTED_EOF
    end

    uri = URI.parse(url)
    raise ArgumentError, 'manifest URL must use HTTP or HTTPS' unless uri.is_a?(URI::HTTP)

    attempts = 0
    begin
      attempts += 1
      uri.open(OPTIONS.dup).read
    rescue *TRANSIENT_ERRORS => e
      raise e unless attempts < ATTEMPTS && transient?(e)

      sleep(RETRY_DELAY * attempts)
      retry
    end
  end

  def self.fetch_json(url)
    JSON.parse(fetch(url))
  end

  # 4xx responses won't succeed on retry; 5xx and network errors might
  def self.transient?(error)
    return true unless error.is_a?(OpenURI::HTTPError)

    error.io.status.first.to_i >= 500
  end
end
