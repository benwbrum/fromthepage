class AiWorkMetadata::Generate < ApplicationInteractor
  attr_accessor :ai_work_metadata

  # Main business logic for AI Work Metadata generation is contained here.
  # AiWorkMetadata params (model, prompt, etc) passed at this point are EXPECTED to be sanitized and validated.
  #
  # All AI Work Metadata generation calls must go through AiWorkMetadata::GenerateJob
  #
  # @params ai_work_metadata: required
  #   - Valid ai_work_metadata record to be used for generation
  def initialize(ai_work_metadata:)
    @ai_work_metadata = ai_work_metadata
    @work = @ai_work_metadata.work
    @collection = @work.collection

    super
  end

  def perform
    if metadata_fields_to_generate?
      response_text, reasoning, metadata, _response = generate_handler.perform

      handle_response(response_text, reasoning, metadata)
    end

    generate_subject_headings if subject_heading_fields.any?
  end

  private

  def metadata_fields_to_generate?
    @collection.metadata_fields.any? { |field| AiWorkMetadata::Lib::ResponseValidator::SKIP_TYPES.exclude?(field.input_type) }
  end

  # Subject headings come from a field's authority list, which is too large for the regular metadata prompt,
  # so each subject heading field gets its own request. Candidates are keyed by field id, like metadata_json.
  def subject_heading_fields
    @subject_heading_fields ||= @collection.metadata_fields
                                           .includes(:subject_heading_inventory)
                                           .select { |field| field.subject_headings? && field.subject_heading_inventory.present? }
  end

  def generate_subject_headings
    candidates = {}
    reasoning = {}
    usage = {}

    subject_heading_fields.each do |field|
      field_candidates, field_reasoning, field_usage =
        AiWorkMetadata::Lib::SubjectHeadingGenerator.new(work: @work, field: field).perform
      candidates[field.id.to_s] = field_candidates
      reasoning[field.id.to_s] = field_reasoning if field_reasoning.present?
      usage[field.id.to_s] = field_usage
    end

    metadata = @ai_work_metadata.metadata.is_a?(Hash) ? @ai_work_metadata.metadata.dup : {}
    metadata['subject_headings'] = usage
    metadata['total_token_count'] = metadata['total_token_count'].to_i + usage.values.sum { |u| u[:total_token_count].to_i }

    @ai_work_metadata.update!(
      subject_heading_candidates: candidates,
      reasoning: [@ai_work_metadata.reasoning, *reasoning.values].compact_blank.join("\n\n").presence,
      metadata: metadata
    )
  end

  def handle_response(response_text, reasoning, metadata)
    validator = AiWorkMetadata::Lib::ResponseValidator.new(
      collection: @collection,
      response_text: response_text
    )

    if validator.valid?
      @ai_work_metadata.update!(
        metadata_json: validator.parsed_json,
        reasoning: reasoning,
        metadata: metadata
      )
    else
      @ai_work_metadata.update!(
        reasoning: reasoning,
        metadata: metadata
      )
      raise ArgumentError, "AI work metadata JSON validation failed: #{validator.errors.join('; ')}"
    end
  end

  def generate_handler
    @generate_handler ||= handler_class.new(
      model: @ai_work_metadata.model,
      prompt: @ai_work_metadata.prompt
    )
  end

  def handler_class
    case @ai_work_metadata.engine
    when 'claude'
      AiWorkMetadata::Lib::Claude::GenerateHandler
    when 'openai'
      AiWorkMetadata::Lib::OpenAi::GenerateHandler
    else
      AiWorkMetadata::Lib::Gemini::GenerateHandler
    end
  end
end
