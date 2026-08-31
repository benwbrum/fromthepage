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
    response_text, reasoning, metadata, _response = generate_handler.perform

    handle_response(response_text, reasoning, metadata)
  end

  private

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
    if @ai_work_metadata.model.start_with?('claude')
      AiWorkMetadata::Lib::Claude::GenerateHandler
    else
      AiWorkMetadata::Lib::Gemini::GenerateHandler
    end
  end
end
