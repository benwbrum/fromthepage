class AiTranscription::Lib::Gemini::TranscribeHandler
  MAX_RETRY = 5
  IMAGE_FETCH_LIMIT = 10

  # Follows key (model_name) value (version)
  # Add custom handling here if the model you are using
  # does not use `v1`
  VERSION_MAP = {
    'gemini-3-pro-preview' => 'v1beta',
    'gemini-3.1-pro-preview' => 'v1beta',
    'gemini-3-flash-preview' => 'v1beta'
  }.freeze

  REASONING_MAP = {
    'gemini-3-pro-preview' => true,
    'gemini-3.1-pro-preview' => true
  }

  def initialize(prompt:, model:, image_url:)
    @prompt = prompt
    @model = model
    @image_url = image_url
  end

  def perform
    attempt = 0
    last_error = nil

    loop do
      attempt += 1

      begin
        response = client.generate_content(payload)

        metadata = extract_usage_metadata(response)

        transcription_text, reasoning_text = extract_texts_from_response(response)

        return [transcription_text, reasoning_text, metadata]
      rescue StandardError => e
        last_error = e

        # Check if this is a 503 error (server overload)
        if e.message.include?('503') && attempt <= MAX_RETRY
          # Calculate exponential backoff delay: 2^attempt seconds
          delay = 2**attempt
          Rails.logger.warn("Gemini API 503 error (attempt #{attempt}/#{MAX_RETRY}). Retrying in #{delay} seconds...")

          sleep(delay)
          next
        end

        # If not a 503 or out of retries, raise the error
        Rails.logger.error("Gemini API error: #{e.message}")
        raise e
      end
    end
  rescue StandardError => e
    Rails.logger.error("Gemini API error: #{e.message}")
    raise e
  end

  private

  def api_key
    return @api_key if defined?(@api_key)

    @api_key = ENV['GEMINI_API_KEY']

    raise ArgumentError, 'GEMINI_API_KEY environment variable is not set' if @api_key.blank?

    @api_key
  end

  def client
    @client ||= ::Gemini.new(
      credentials: {
        service: 'generative-language-api',
        api_key: api_key,
        version: VERSION_MAP[@model] || 'v1'
      },
      options: { model: @model }
    )
  end

  def fetch_and_encode_image(url:, limit: IMAGE_FETCH_LIMIT)
    raise ArgumentError, 'Too many HTTP redirects' if limit.zero?

    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess
      Base64.strict_encode64(response.body)
    when Net::HTTPRedirection
      location = response['location']
      Rails.logger.info("Following redirect to: #{location}")
      fetch_and_encode_image(url: location, limit: limit - 1)
    else
      raise "Failed to fetch image from #{url}: #{response.code} #{response.message}"
    end
  end

  def payload
    return @payload if defined?(@payload)

    @payload = {
      contents: {
        role: 'user',
        parts: [
          { text: @prompt },
          {
            inline_data: {
              mime_type: 'image/jpeg',
              data: fetch_and_encode_image(url: @image_url)
            }
          }
        ]
      }
    }

    if REASONING_MAP[@model]
      @payload = @payload.merge({
        generation_config: {
          thinking_config: {
            include_thoughts: true
          }
        }
      })
    end

    @payload
  end

  def extract_texts_from_response(response)
    parts = response.dig('candidates', 0, 'content', 'parts') || []

    transcription_text = []
    reasoning_text = []

    parts.each do |part|
      next unless part['text']

      if ActiveRecord::Type::Boolean.new.cast(part['thought'])
        reasoning_text << part['text']
      else
        transcription_text << part['text']
      end
    end

    [transcription_text.join('').strip, reasoning_text.join('').strip]
  end

  def extract_usage_metadata(response)
    usage = response['usageMetadata'] || {}

    {
      prompt_token_count: usage['promptTokenCount'],
      candidates_token_count: usage['candidatesTokenCount'],
      thoughts_token_count: usage['thoughtsTokenCount'],
      total_token_count: usage['totalTokenCount']
    }.compact
  end
end
