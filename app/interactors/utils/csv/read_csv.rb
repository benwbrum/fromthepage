require 'csv'

class Utils::Csv::ReadCsv
  def self.perform(csv_file, headers: true)
    CSV.read(csv_file, headers: headers)
  rescue StandardError => _e # :nocov:
    contents = File.read(csv_file)
    detection = CharlockHolmes::EncodingDetector.detect(contents)

    CSV.read(
      csv_file,
      encoding: "bom|#{detection[:encoding]}",
      liberal_parsing: true,
      headers: headers
    )
  end # :nocov:
end
