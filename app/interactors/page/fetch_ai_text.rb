class Page::FetchAiText < ApplicationInteractor
  attr_accessor :page

  def initialize(page:, model: 'gemini-2.5-pro', provider: 'gemini')
    @page = page
    @model = model
    @provider = provider.to_s.downcase
    super
  end

  def perform
    # Load appropriate transcriber based on provider
    case @provider
    when 'chatgpt', 'openai'
      require 'chatgpt/text_transcriber'
      transcriber_class = Chatgpt::TextTranscriber
      provider_name = 'ChatGPT'
    when 'gemini'
      require 'gemini/text_transcriber'
      transcriber_class = Gemini::TextTranscriber
      provider_name = 'Gemini AI'
    else
      context.message = "Unknown AI provider: #{@provider}. Supported providers: gemini, chatgpt"
      context.fail!
      return
    end

    # Get the page image URL
    image_url = @page.image_url_for_download

    if image_url.blank?
      context.message = 'Page has no image to transcribe'
      context.fail!
      return
    end

    # Call the appropriate API to transcribe the image
    transcribed_text = transcriber_class.transcribe_image(image_url, model: @model)

    # Save the transcribed text to the page
    @page.ai_plaintext = transcribed_text

    context.message = "Successfully transcribed text from image using #{provider_name}"
  rescue StandardError => e
    context.message = "Failed to transcribe image: #{context.message || e.message}"
    context.fail!
  end
end
