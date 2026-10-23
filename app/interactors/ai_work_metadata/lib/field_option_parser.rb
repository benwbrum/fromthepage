module AiWorkMetadata::Lib::FieldOptionParser
  def self.parse(options_text)
    return [] if options_text.blank?

    JSON.parse(options_text)
  rescue JSON::ParserError
    options_text.split(/[;,\n]/).map(&:strip).reject(&:blank?)
  end
end
