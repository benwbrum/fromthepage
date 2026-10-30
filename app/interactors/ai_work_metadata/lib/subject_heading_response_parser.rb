# Turns the model's {"headings": [{"id": "H0123", ...}]} response into subject heading snapshots,
# keeping only IDs that exist in the vocabulary. If the JSON is malformed (e.g. cut off mid-response),
# the IDs are salvaged with a pattern match rather than discarding the whole response.
class AiWorkMetadata::Lib::SubjectHeadingResponseParser
  attr_reader :invalid_ids

  def initialize(response_text:, prompt_builder:)
    @response_text = response_text.to_s
    @prompt_builder = prompt_builder
    @invalid_ids = []
  end

  def candidates
    @candidates ||= ids.uniq.filter_map do |id|
      heading = @prompt_builder.heading_for(id)
      @invalid_ids << id if heading.nil?
      heading&.snapshot
    end.uniq
  end

  def malformed?
    parsed.nil?
  end

  private

  def ids
    return @response_text.scan(/"id"\s*:\s*"(H\d+)"/).flatten if parsed.nil?

    Array(parsed['headings']).filter_map { |h| h['id'].to_s if h.is_a?(Hash) }
  end

  def parsed
    return @parsed if defined?(@parsed)

    text = @response_text.strip.gsub(/\A```(?:json)?\n?/, '').gsub(/\n?```\z/, '')
    @parsed = JSON.parse(text)
    @parsed = nil unless @parsed.is_a?(Hash)
    @parsed
  rescue JSON::ParserError
    @parsed = nil
  end
end
