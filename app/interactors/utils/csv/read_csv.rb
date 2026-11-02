require 'csv'

class Utils::Csv::ReadCsv
  # Decode bounded, in-memory uploads using the same detector as file imports.
  def self.decode(contents)
    bytes = contents.b
    return ''.encode(Encoding::UTF_8) if bytes.empty?

    detection = CharlockHolmes::EncodingDetector.detect(bytes)
    encoding = detection && detection[:encoding]
    utf8 = bytes.dup.force_encoding(Encoding::UTF_8)
    # Preserve valid UTF-8, but allow the detector to recognize UTF-16/32 text.
    encoding = 'UTF-8' if utf8.valid_encoding? && !encoding.to_s.start_with?('UTF-16', 'UTF-32')
    raise ArgumentError, 'The CSV text could not be read. Please export it as CSV and try again.' unless encoding

    bytes.force_encoding(encoding).encode(Encoding::UTF_8).delete_prefix("\uFEFF")
  rescue EncodingError
    raise ArgumentError, 'The CSV text could not be read. Please export it as CSV and try again.'
  end

  def self.perform(csv_file, headers: true)
    CSV.read(csv_file, headers: headers)
  rescue StandardError => _e # :nocov:
    contents = File.read(csv_file)
    detection = CharlockHolmes::EncodingDetector.detect(contents)

    CSV.read(
      csv_file,
      encoding: "bom|#{detection[:encoding]}",
      liberal_parsing: true,
      headers: headers,
      invalid: :replace,
      undef: :replace,
      replace: ''
    )
  end # :nocov:
end
