class AiTranscription::Lib::FieldBasedResponseValidator
  SKIP_TYPES = %w[description instruction].freeze

  def initialize(collection:, response_text:)
    @response_text = response_text
    @fields = collection.transcription_fields.reject { |f| SKIP_TYPES.include?(f.input_type) }
    @errors = []
    @parsed_json = nil
  end

  def valid?
    parse_json
    return false if @parsed_json.nil?

    validate_field_keys
    validate_field_types
    @errors.empty?
  end

  def parsed_json
    @parsed_json
  end

  def errors
    @errors
  end

  private

  def parse_json
    @parsed_json = JSON.parse(strip_markdown(@response_text))
  rescue JSON::ParserError => e
    @errors << "Invalid JSON: #{e.message}"
  end

  # Strip markdown code fences that Gemini sometimes wraps JSON in
  def strip_markdown(text)
    text.strip
        .gsub(/\A```(?:json)?\n?/, '')
        .gsub(/\n?```\z/, '')
        .strip
  end

  def validate_field_keys
    expected_keys = @fields.map { |f| f.id.to_s }
    missing = expected_keys.reject { |k| @parsed_json.key?(k) }
    @errors << "Missing fields: #{missing.join(', ')}" if missing.any?
  end

  def validate_field_types
    @fields.each do |field|
      value = @parsed_json[field.id.to_s]
      next if value.nil?

      case field.input_type
      when 'select'
        validate_select(field, value)
      when 'spreadsheet'
        validate_spreadsheet(field, value)
      end
    end
  end

  def validate_select(field, value)
    return unless field.options.present?

    valid_options = parse_options(field.options)
    return if valid_options.include?(value.to_s)

    @errors << "Field \"#{field.label}\" (#{field.id}): invalid select value \"#{value}\", " \
               "expected one of: #{valid_options.join(', ')}"
  end

  def validate_spreadsheet(field, value)
    unless value.is_a?(Array)
      @errors << "Field \"#{field.label}\" (#{field.id}): expected array for spreadsheet field"
      return
    end

    expected_col_ids = field.spreadsheet_columns.map { |c| c.id.to_s }
    value.each_with_index do |row, i|
      unless row.is_a?(Hash)
        @errors << "Field \"#{field.label}\" (#{field.id}): row #{i + 1} is not an object"
        next
      end

      missing = expected_col_ids.reject { |k| row.key?(k) }
      if missing.any?
        @errors << "Field \"#{field.label}\" (#{field.id}): row #{i + 1} missing columns: #{missing.join(', ')}"
      end
    end
  end

  def parse_options(options_text)
    return [] if options_text.blank?
    JSON.parse(options_text)
  rescue JSON::ParserError
    options_text.split(/[;,]/).map(&:strip).reject(&:blank?)
  end
end
