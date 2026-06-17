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

    @ai_transcription.update!(
      source_text: source_text,
      reasoning: reasoning,
      metadata: metadata
    )

    return if @ai_transcription.source_text.present? || @ai_transcription.reasoning.present?

    raise ArgumentError, "AI Transcription has blank text and reasoning.\nResponse:\n#{response}"
  end

  private

  def image_url
    return @image_url if defined?(@image_url)

    @image_url = @page.image_url_for_download

    raise ArgumentError, 'Page has no image to transcribe' if @image_url.blank?

    @image_url
  end

  def transcribe_handler
    @transcribe_handler ||= handler_class.new(
      model: @ai_transcription.model,
      prompt: @ai_transcription.prompt,
      image_url: image_url
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
