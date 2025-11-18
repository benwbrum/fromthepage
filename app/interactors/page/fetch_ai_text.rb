class Page::FetchAiText < ApplicationInteractor
  attr_accessor :page

  def initialize(page:, model: 'gemini-2.5-pro')
    @page = page
    @model = model
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
    transcribed_text = Gemini::TextTranscriber.transcribe_image(image_url, model: @model)

    # Save the transcribed text to the page
    @page.ai_plaintext = transcribed_text

    context.message = 'Successfully transcribed text from image using Gemini AI'
  rescue StandardError => e
    context.message = "Failed to transcribe image: #{context.message || e.message}"
    context.fail!
  end
end
