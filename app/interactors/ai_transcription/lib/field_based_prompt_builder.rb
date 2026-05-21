class AiTranscription::Lib::FieldBasedPromptBuilder
  SKIP_TYPES = %w[description instruction].freeze

  def initialize(collection:)
    @collection = collection
    @fields = collection.transcription_fields.reject { |f| SKIP_TYPES.include?(f.input_type) }
  end

  def build
    <<~PROMPT
      You are transcribing a historical document image into structured fields.
      Extract the following fields from the image and return your results as a valid JSON object.
      Use the numeric field ID shown before each field name as the JSON key (as a string).

      Fields to extract:
      #{field_list}

      Rules:
      - Return ONLY a valid JSON object. Do not include any text, explanation, or markdown outside the JSON.
      - Use the numeric field ID as each key (as a string).
      - If a field is not present or legible in the image, use null as the value.
      - For select fields, use one of the listed options exactly as shown, or null if none apply.
      - For spreadsheet fields, return an array of row objects using the column IDs as keys.

      Expected JSON format:
      #{example_json}
    PROMPT
  end

  private

  def field_list
    @fields.map { |f| format_field(f) }.join("\n")
  end

  def format_field(field)
    desc = "- #{field.id} \"#{field.label}\" (#{field.input_type})"
    case field.input_type
    when 'select'
      opts = parse_options(field.options)
      desc += ", options: [#{opts.join(', ')}]" if opts.any?
    when 'spreadsheet'
      cols = field.spreadsheet_columns.map { |c| "#{c.id} \"#{c.label}\" (#{c.input_type})" }.join(', ')
      desc += " with columns: #{cols}" if cols.present?
    end
    desc
  end

  def example_json
    example = @fields.each_with_object({}) { |f, h| h[f.id.to_s] = example_value(f) }
    JSON.pretty_generate(example)
  end

  def example_value(field)
    case field.input_type
    when 'date' then 'YYYY-MM-DD'
    when 'select'
      opts = parse_options(field.options)
      opts.first || 'option_value'
    when 'spreadsheet'
      cols = field.spreadsheet_columns
      [cols.each_with_object({}) { |c, h| h[c.id.to_s] = example_col_value(c) }]
    else
      'extracted text'
    end
  end

  def example_col_value(col)
    case col.input_type
    when 'date'    then 'YYYY-MM-DD'
    when 'numeric' then '0'
    when 'checkbox' then 'true'
    when 'select'
      opts = parse_options(col.options)
      opts.first || 'option_value'
    else
      'text value'
    end
  end

  def parse_options(options_text)
    return [] if options_text.blank?
    JSON.parse(options_text)
  rescue JSON::ParserError
    options_text.split(/[;,]/).map(&:strip).reject(&:blank?)
  end
end
