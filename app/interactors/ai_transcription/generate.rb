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

    metadata = @ai_transcription.metadata.is_a?(Hash) ? @ai_transcription.metadata.dup : {}
    metadata['provider_error_details'] = provider_error_details(response)
    @ai_transcription.update!(metadata: metadata)

    provider_error = provider_error_summary(metadata['provider_error_details'])
    details = provider_error.present? ? "\nProvider details: #{provider_error}" : ''

    raise ArgumentError, "AI Transcription has blank text and reasoning.#{details}"
  end

  def provider_error_details(response)
    response = {} unless response.is_a?(Hash)
    candidate = response.dig('candidates', 0) || {}

    {
      'finish_reason' => candidate['finishReason'],
      'finish_message' => candidate['finishMessage'],
      'citation_sources' => candidate.dig('citationMetadata', 'citationSources') || [],
      'model_version' => response['modelVersion'],
      'response_id' => response['responseId'],
      'usage_metadata' => response['usageMetadata'],
      'raw_response' => response
    }.compact
  end

  def provider_error_summary(provider_error_details)
    provider_error_parts = []
    finish_reason = provider_error_details['finish_reason']
    finish_message = provider_error_details['finish_message']
    provider_error_parts << "finishReason=#{finish_reason}" if finish_reason.present?
    provider_error_parts << "finishMessage=#{finish_message}" if finish_message.present?
    provider_error_parts.join('; ')
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
    @image_url = @page.image_url_for_ai
  end

  def local_image_path
    @local_image_path ||= @page.local_image_path
  end

  def transcribe_handler
    raise ArgumentError, 'Page has no image to transcribe' if image_url.blank? && local_image_path.blank?

    Rails.logger.info("AiTranscription::Generate image URL for page #{@page.id}: #{image_url || local_image_path}")

    @transcribe_handler ||= handler_class.new(
      model: @ai_transcription.model,
      prompt: @ai_transcription.prompt,
      image_url: image_url,
      image_path: local_image_path
    )
  end

  def handler_class
    if @ai_transcription.model.start_with?('claude')
      AiTranscription::Lib::Claude::TranscribeHandler
    else
      AiTranscription::Lib::Gemini::TranscribeHandler
    end
  end
end
