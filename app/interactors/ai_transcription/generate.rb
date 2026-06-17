class AiTranscription::Generate < ApplicationInteractor
  attr_accessor :ai_transcription

  # Main business logic for AI Transcription generation is contained here.
  # AiTranscription params (model, prompt, etc) passed at this point are EXPECTED to be sanitized and validated.
  #
  # All AI Transcription generation call must go through AiTranscription::GenerateJob
  #
  # @params ai_transcription: required
  #   - Valid ai_transcription record to be used for generation
  def initialize(ai_transcription:)
    @ai_transcription = ai_transcription
    @page = @ai_transcription.page
    @collection = @page.collection

    super
  end

  def perform
    source_text, reasoning, metadata, response = transcribe_handler.perform

    if @collection.field_based
      handle_field_based_response(source_text, reasoning, metadata)
    else
      handle_standard_response(source_text, reasoning, metadata, response)
    end
  end

  private

  def handle_standard_response(source_text, reasoning, metadata, response)
    @ai_transcription.update!(
      source_text: source_text,
      reasoning: reasoning,
      metadata: metadata
    )

    return if @ai_transcription.source_text.present? || @ai_transcription.reasoning.present?

    finish_reason = response.dig('candidates', 0, 'finishReason')
    finish_message = response.dig('candidates', 0, 'finishMessage')
    provider_error_parts = []
    provider_error_parts << "finishReason=#{finish_reason}" if finish_reason.present?
    provider_error_parts << "finishMessage=#{finish_message}" if finish_message.present?
    provider_error = provider_error_parts.join('; ')
    details = provider_error.present? ? "\nProvider details: #{provider_error}" : ''

    raise ArgumentError, "AI Transcription has blank text and reasoning.#{details}\nResponse:\n#{response}"
  end

  def handle_field_based_response(source_text, reasoning, metadata)
    validator = AiTranscription::Lib::FieldBasedResponseValidator.new(
      collection: @collection,
      response_text: source_text
    )

    if validator.valid?
      @ai_transcription.update!(
        transcription_json: validator.parsed_json,
        reasoning: reasoning,
        metadata: metadata
      )
    else
      @ai_transcription.update!(
        source_text: source_text,
        reasoning: reasoning,
        metadata: metadata
      )
      raise ArgumentError, "Field-based AI transcription JSON validation failed: #{validator.errors.join('; ')}"
    end
  end

  def image_url
    return @image_url if defined?(@image_url)

    @image_url = @page.image_url_for_download

    raise ArgumentError, 'Page has no image to transcribe' if @image_url.blank?

    @image_url
  end

  # TODO: When we support claude, this should handle what transcribe_handler is used
  # We will refactor this to inherit into one `BaseHandler` so it follows consistent form
  # for each AI models
  def transcribe_handler
    @transcribe_handler ||= AiTranscription::Lib::Gemini::TranscribeHandler.new(
      model: @ai_transcription.model,
      prompt: @ai_transcription.prompt,
      image_url: image_url
    )
  end
end
