require 'openai'
require 'net/http'
require 'base64'

module Chatgpt
  class TextTranscriber
    # Transcribes text from a page image using OpenAI's GPT-4 Vision model
    # Defaults to gpt-4o but can be configured via model parameter
    #
    # Implements exponential backoff retry logic for rate limit and server errors
    #
    # @param image_url [String] The URL of the page image to transcribe
    # @param prompt [String] Optional custom prompt for transcription
    # @param model [String] The GPT model to use (default: 'gpt-4o')
    # @param max_retries [Integer] Maximum number of retry attempts for transient errors
    # @return [String] The transcribed text from the image
    def self.transcribe_image(image_url, prompt: nil, model: 'gpt-4o', max_retries: 5)
      api_key = ENV['OPENAI_API_KEY']
      raise ArgumentError, 'OPENAI_API_KEY environment variable is not set' if api_key.blank?

      model ||= 'gpt-4o'

      client = OpenAI::Client.new(access_token: api_key)

      # Use provided prompt or default transcription prompt
      transcription_prompt = prompt || default_prompt

      # Download and encode the image
      image_data = fetch_and_encode_image(image_url)
      
      # Prepare the image URL as a data URI
      image_data_uri = "data:image/jpeg;base64,#{image_data}"

      # Make request to OpenAI API with retry logic
      attempt = 0
      last_error = nil

      loop do
        attempt += 1

        begin
          response = client.chat(
            parameters: {
              model: model,
              messages: [
                {
                  role: 'user',
                  content: [
                    { type: 'text', text: transcription_prompt },
                    { type: 'image_url', image_url: { url: image_data_uri } }
                  ]
                }
              ],
              max_tokens: 4096
            }
          )

          # Extract transcribed text from response
          return extract_text_from_response(response)
        rescue StandardError => e
          last_error = e

          # Check if this is a retryable error (rate limit, server error, timeout)
          retryable = e.message.include?('429') || # Rate limit
                      e.message.include?('503') || # Service unavailable
                      e.message.include?('502') || # Bad gateway
                      e.message.include?('500') || # Internal server error
                      e.message.include?('timeout')

          if retryable && attempt <= max_retries
            # Calculate exponential backoff delay: 2^attempt seconds
            delay = 2**attempt
            Rails.logger.warn("OpenAI API error (attempt #{attempt}/#{max_retries}): #{e.message}. Retrying in #{delay} seconds...")
            sleep(delay)
            next
          end

          # If not retryable or out of retries, raise the error
          Rails.logger.error("OpenAI API error: #{e.message}")
          raise
        end
      end
    rescue StandardError => e
      Rails.logger.error("OpenAI API error: #{e.message}")
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

    # Extracts transcribed text from OpenAI API response
    #
    # @param response [Hash] The response from OpenAI API
    # @return [String] The extracted text
    def self.extract_text_from_response(response)
      if response.dig('choices', 0, 'message', 'content')
        response.dig('choices', 0, 'message', 'content').strip
      else
        raise 'Unexpected response format from OpenAI API'
      end
    end

    # Default prompt for transcribing historical documents
    #
    # @return [String] The default transcription prompt
    def self.default_prompt
      @default_prompt ||= File.read(
        File.join(Rails.root, 'lib', 'chatgpt', 'transcription_prompt.txt')
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
