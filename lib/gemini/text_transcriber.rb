require 'gemini-ai'
require 'net/http'
require 'base64'

module Gemini
  class TextTranscriber
    # Follows key (model_name) value (version)
    # Add custom handling here if the model you are using
    # does not use `v1`
    VERSION_MAP = {
      'gemini-3.1-pro-preview' => 'v1beta',
      'gemini-3-flash-preview' => 'v1beta'
    }.freeze

    REASONING_MAP = {
      'gemini-3.1-pro-preview' => true
    }

    # Transcribes text from a page image using Google's Gemini multi-modal model
    # Defaults to AiTranscription::DEFAULT_MODEL but can be configured via model parameter
    #
    # Implements exponential backoff retry logic for 503 errors (server overload) and 429 errors (rate limit)
    #
    # @param image_url [String] The URL of the page image to transcribe
    # @param prompt [String] Optional custom prompt for transcription
    # @param model [String] Optional custom model to use. Defaults to AiTranscription::DEFAULT_MODEL
    # @param max_retries [Integer] Maximum number of retry attempts for 503/429 errors
    # @return [String] The transcribed text from the image
    def self.transcribe_image(image_url, prompt: nil, model: AiTranscription::DEFAULT_MODEL, max_retries: 5)
      api_key = ENV['GEMINI_API_KEY']
      raise ArgumentError, 'GEMINI_API_KEY environment variable is not set' if api_key.blank?

      model ||= AiTranscription::DEFAULT_MODEL

      client = ::Gemini.new(
        credentials: {
          service: 'generative-language-api',
          api_key: api_key,
          version: VERSION_MAP[model] || 'v1'
        },
        options: { model: model, server_sent_events: true }
      )

      # Use provided prompt or default transcription prompt
      transcription_prompt = prompt || default_prompt

      # Download and encode the image
      image_data = fetch_and_encode_image(image_url)

      # Make request to Gemini API with retry logic
      attempt = 0
      last_error = nil

      loop do
        attempt += 1

        begin
          payload = {
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
          }

          if REASONING_MAP[model]
            payload = payload.merge({
              generation_config: {
                thinking_config: {
                  include_thoughts: true
                }
              }
            })
          end

          response = client.stream_generate_content(payload)

          # TODO: Make options customizable for gemini and add to metadata
          metadata = {}

          # Extract transcribed text from response
          return [extract_text_from_response(response), extract_reasoning_from_response(response), metadata, transcription_prompt]
        rescue StandardError => e
          last_error = e

          # Check if this is a 503 error (server overload) or 429 error (rate limit)
          if (e.message.include?('503') || e.message.include?('429')) && attempt <= max_retries
            # Calculate exponential backoff delay: 2^attempt seconds
            delay = 2**attempt
            error_type = e.message.include?('429') ? '429 (rate limit)' : '503 (server overload)'
            Rails.logger.warn("Gemini API #{error_type} error (attempt #{attempt}/#{max_retries}). Retrying in #{delay} seconds...")
            sleep(delay)
            next
          end

          # If not a 503 or out of retries, raise the error
          Rails.logger.error("Gemini API error: #{e.message}")
          raise
        end
      end
    rescue StandardError => e
      Rails.logger.error("Gemini API error: #{e.message}")
      raise
    end

    # Fetches an image from a URL and encodes it as base64
    # Follows redirects up to a maximum of 10 times
    #
    # @param url [String] The URL of the image
    # @param limit [Integer] Maximum number of redirects to follow
    # @return [String] Base64-encoded image data
    def self.fetch_and_encode_image(url, limit = 10)
      raise ArgumentError, 'Too many HTTP redirects' if limit.zero?

      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)

      case response
      when Net::HTTPSuccess
        Base64.strict_encode64(response.body)
      when Net::HTTPRedirection
        location = response['location']
        Rails.logger.info("Following redirect to: #{location}")
        fetch_and_encode_image(location, limit - 1)
      else
        raise "Failed to fetch image from #{url}: #{response.code} #{response.message}"
      end
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
          accumulated_text << part['text'] if part['text'] && !ActiveRecord::Type::Boolean.new.cast(part['thought'])
        end
      end

      accumulated_text.join('').strip
    end

    # Extracts reasoning text from Gemini API response
    #
    # @param response [Array] The response from Gemini API
    # @return [String] The extracted reasoning text
    def self.extract_reasoning_from_response(response)
      accumulated_text = []

      response.each do |event|
        next unless event.dig('candidates', 0, 'content', 'parts')

        parts = event.dig('candidates', 0, 'content', 'parts')
        parts.each do |part|
          accumulated_text << part['text'] if part['text'] && ActiveRecord::Type::Boolean.new.cast(part['thought'])
        end
      end

      accumulated_text.join('').strip
    end

    # Default prompt for transcribing historical documents
    #
    # @return [String] The default transcription prompt
    def self.default_prompt
      @default_prompt ||= File.read(
        File.join(Rails.root, 'lib', 'transcription_prompt.txt')
      )
    rescue Errno::ENOENT
      # Fallback prompt if file doesn't exist
      'Please transcribe all the text you see in this image. ' \
      'Preserve the original formatting, line breaks, and layout as much as possible. ' \
      'If the text is handwritten, do your best to interpret it accurately. ' \
      'Do not add any commentary or explanations - only provide the transcribed text.'
    end
  end
end
