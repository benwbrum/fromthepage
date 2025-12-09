class Page::FetchAiText < ApplicationInteractor
  attr_accessor :page

  def initialize(page:, model: 'gemini-2.5-pro', prompt: nil)
    @page = page
    @model = model
    @prompt = prompt
    super
  end

  def perform
    require 'gemini/text_transcriber'

    # Get the page image URL
    image_url = @page.image_url_for_download

    if image_url.blank?
      context.message = 'Page has no image to transcribe'
      context.fail!
      return
    end

    # Call Gemini API to transcribe the image
    transcribed_text, reasoning, metadata, prompt = Gemini::TextTranscriber.transcribe_image(image_url, model: @model, prompt: @prompt)

    # Save the transcribed text to the page
    ai_transcription = AiTranscription.new(
      page_id: @page.id,
      source_text: transcribed_text,
      reasoning: reasoning,
      model: @model,
      metadata: metadata,
      prompt: prompt
    )
    ai_transcription.save!

    context.message = 'Successfully transcribed text from image using Gemini AI'
  rescue StandardError => e
    context.message = "Failed to transcribe image: #{context.message || e.message}"
    context.fail!
  end
end
