class AiWorkMetadata::Lib::PromptBuilder
  SKIP_TYPES = %w[instruction].freeze

  def initialize(work:)
    @work = work
    @collection = work.collection
    ordered_fields = @collection.metadata_fields.order(:line_number, :position)
    @prompt_fields = ordered_fields
    @fields = ordered_fields.reject { |field| SKIP_TYPES.include?(field.input_type) }
  end

  def build
    <<~PROMPT
      You are cataloging a historical document based on its transcribed text.
      Extract descriptive metadata about the document and return your results as a valid JSON object.
      Use the numeric field ID shown before each field name as the JSON key (as a string).
      #{instructions}
      Fields to extract:
      #{field_list}

      Rules:
      - Return ONLY a valid JSON object. Do not include any text, explanation, or markdown outside the JSON.
      - Use the numeric field ID as each key (as a string).
      - Lines beginning with "Instruction:" are guidance for the fields that follow, not fields to include in the JSON.
      - If a field cannot be determined from the text, use null as the value.
      - For select fields, use one of the listed options exactly as shown, or null if none apply.
      - For multiselect fields, return an array of one or more of the listed options, or an empty array if none apply.

      Expected JSON format:
      #{example_json}

      Document text:
      #{@work.verbatim_transcription_plaintext}
    PROMPT
  end

  private

  def instructions
    return '' if @collection.description_instructions.blank?

    "\nAdditional instructions from the project owner:\n#{@collection.description_instructions}\n"
  end

  def field_list
    @prompt_fields.map { |field| format_prompt_field(field) }.join("\n")
  end

  def format_prompt_field(field)
    return "- Instruction: #{field.label}" if field.input_type == 'instruction'

    format_field(field)
  end

  def format_field(field)
    desc = "- #{field.id} \"#{field.label}\" (#{field.input_type})"
    if %w[select multiselect].include?(field.input_type)
      opts = parse_options(field.options)
      desc += ", options: [#{opts.join(', ')}]" if opts.any?
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
    when 'multiselect'
      opts = parse_options(field.options)
      opts.first(1).presence || ['option_value']
    else
      'extracted text'
    end
  end

  def parse_options(options_text)
    return [] if options_text.blank?
    JSON.parse(options_text)
  rescue JSON::ParserError
    options_text.split(/[;,\n]/).map(&:strip).reject(&:blank?)
  end
end
