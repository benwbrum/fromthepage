module InternetArchiveTranslator
  IIIF_MANIFEST_URL = 'https://iiif.archive.org/iiif/%<identifier>s/manifest.json'.freeze
  ARCHIVE_HOST = /\A(www\.)?archive\.org\z/i
  # IA identifiers are limited to ASCII letters, digits, dots, dashes and underscores
  IDENTIFIER = /\A[A-Za-z0-9._-]+\z/

  # Maps an item page such as https://archive.org/details/b29000427_0001/page/n13/mode/2up
  # to its IIIF manifest, https://iiif.archive.org/iiif/b29000427_0001/manifest.json
  def self.ia_url_to_iiif(url)
    uri = URI.parse(url.to_s.strip)
    unless uri.is_a?(URI::HTTP) && uri.host&.match?(ARCHIVE_HOST)
      raise ArgumentError, "Internet Archive URLs must be of the form https://archive.org/details/IDENTIFIER: #{url}"
    end

    identifier = uri.path.to_s.match(%r{\A/details/([^/]+)})&.[](1)
    identifier = CGI.unescape(identifier) if identifier
    unless identifier&.match?(IDENTIFIER)
      raise ArgumentError, "Internet Archive URL does not contain a valid item identifier: #{url}"
    end

    format(IIIF_MANIFEST_URL, identifier: identifier)
  rescue URI::InvalidURIError
    raise ArgumentError, "Internet Archive URLs must be of the form https://archive.org/details/IDENTIFIER: #{url}"
  end
end
