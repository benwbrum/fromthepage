module Gemini
  class TextTranscriber
    # Transcribes text from a page image using Google's Gemini 2.5 multi-modal model
    #
    # @param image_url [String] The URL of the page image to transcribe
    # @param prompt [String] Optional custom prompt for transcription
    # @return [String] The transcribed text from the image
    def self.transcribe_image(image_url, prompt: nil)
      api_key = ENV['GEMINI_API_KEY']
      raise ArgumentError, 'GEMINI_API_KEY environment variable is not set' if api_key.blank?

      client = Gemini.new(
        credentials: {
          service: 'generative-language-api',
          api_key: api_key
        },
        options: { model: 'gemini-2.0-flash-exp', server_sent_events: true }
      )

      # Use provided prompt or default transcription prompt
      transcription_prompt = prompt || default_prompt

      # Download and encode the image
      image_data = fetch_and_encode_image(image_url)

      # Make request to Gemini API
      response = client.stream_generate_content({
        contents: {
          role: 'user',
          parts: [
            { text: transcription_prompt },
            {
              inline_data: {
                mime_type: 'image/jpeg',
                data: image_data
              }
            }
          ]
        }
      })

      # Extract transcribed text from response
      extract_text_from_response(response)
    rescue StandardError => e
      Rails.logger.error("Gemini API error: #{e.message}")
      raise
    end

    # Fetches an image from a URL and encodes it as base64
    #
    # @param url [String] The URL of the image
    # @return [String] Base64-encoded image data
    def self.fetch_and_encode_image(url)
      require 'net/http'
      require 'base64'

      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Failed to fetch image from #{url}: #{response.code} #{response.message}"
      end

      Base64.strict_encode64(response.body)
    end

    # Extracts transcribed text from Gemini API response
    #
    # @param response [Array] The response from Gemini API
    # @return [String] The extracted text
    def self.extract_text_from_response(response)
      accumulated_text = []

      response.each do |event|
        next unless event.dig('candidates', 0, 'content', 'parts')

        parts = event.dig('candidates', 0, 'content', 'parts')
        parts.each do |part|
          accumulated_text << part['text'] if part['text']
        end
      end

      accumulated_text.join('').strip
    end

    # Default prompt for transcribing historical documents
    #
    # @return [String] The default transcription prompt
    def self.default_prompt
      @default_prompt ||= File.read(
        File.join(Rails.root, 'lib', 'gemini', 'transcription_prompt.txt')
      )
    rescue Errno::ENOENT
      # Fallback prompt if file doesn't exist
      "Please transcribe all the text you see in this image. " \
      "Preserve the original formatting, line breaks, and layout as much as possible. " \
      "If the text is handwritten, do your best to interpret it accurately. " \
      "Do not add any commentary or explanations - only provide the transcribed text."
    end
  end
end
