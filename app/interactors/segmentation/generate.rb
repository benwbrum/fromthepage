class Segmentation::Generate
  PROMPT = "Is this the first page of a historic document? (i.e. a letter with a salutation or dateline, an address page, a header or preamble text.) Answer only yes or no.".freeze
  MODEL = AiTranscription::DEFAULT_MODEL

  def initialize(page:)
    @page = page
  end

  def perform
    image_url = @page.image_url_for_download
    raise ArgumentError, "Page #{@page.id} has no image to segment" if image_url.blank?

    text, = AiTranscription::Lib::Gemini::TranscribeHandler.new(
      prompt: PROMPT,
      model: MODEL,
      image_url: image_url
    ).perform

    is_candidate = text.strip.downcase.start_with?('yes')
    @page.update_column(:is_first_page_candidate, is_candidate)
  end
end
