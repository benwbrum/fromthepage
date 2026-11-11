require Rails.root.join('lib/gemini/model_support')

class AiWorkMetadata::Lib::Gemini::GenerateHandler
  MAX_RETRY = 5

  # Follows key (model_name) value (version)
  # Add custom handling here if the model you are using
  # does not use `v1`
  VERSION_MAP = ::Gemini::ModelSupport::VERSION_MAP
  REASONING_MAP = ::Gemini::ModelSupport::REASONING_MAP

  # @params system_instruction: optional
  #   - Text sent ahead of the prompt that is the same for every request (e.g. a vocabulary),
  #     so Gemini can cache it across requests
  # @params json_response: optional
  #   - Ask Gemini to respond with JSON only
  def initialize(prompt:, model:, system_instruction: nil, json_response: false)
    @prompt = prompt
    @model = model
    @system_instruction = system_instruction
    @json_response = json_response
  end

  def perform
    attempt = 0

    loop do
      attempt += 1

      begin
        response = client.generate_content(payload)

        metadata = extract_usage_metadata(response)

        metadata_text, reasoning_text = extract_texts_from_response(response)

        return [metadata_text, reasoning_text, metadata, response]
      rescue => e
        # Check if this is a 503 error (server overload)
        if e.message.include?('503') && attempt <= MAX_RETRY
          # Calculate exponential backoff delay: 2^attempt seconds
          delay = 2**attempt
          Rails.logger.warn("Gemini API 503 error (attempt #{attempt}/#{MAX_RETRY}). Retrying in #{delay} seconds...")

          sleep(delay)
          next
        end

        # If not a 503 or out of retries, raise the error
        Rails.logger.error("Gemini API error: #{sanitized_message(e)}")
        raise e
      end
    end
  end

  private

  def sanitized_message(error)
    AiTranscription::Lib::ErrorMessageSanitizer.sanitize(error.message)
  end

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

  def payload
    return @payload if defined?(@payload)

    @payload = {
      contents: {
        role: 'user',
        parts: [
          { text: @prompt }
        ]
      }
    }

    @payload[:system_instruction] = { parts: [{ text: @system_instruction }] } if @system_instruction.present?

    generation_config = {}
    generation_config[:thinking_config] = { include_thoughts: true } if REASONING_MAP[@model]
    generation_config[:response_mime_type] = 'application/json' if @json_response
    @payload[:generation_config] = generation_config if generation_config.any?

    @payload
  end

  def extract_texts_from_response(response)
    parts = response.dig('candidates', 0, 'content', 'parts') || []

    metadata_text = []
    reasoning_text = []

    parts.each do |part|
      next unless part['text']

      if ActiveRecord::Type::Boolean.new.cast(part['thought'])
        reasoning_text << part['text']
      else
        metadata_text << part['text']
      end
    end

    [metadata_text.join('').strip, reasoning_text.join('').strip]
  end

  def extract_usage_metadata(response)
    usage = response['usageMetadata'] || {}

    {
      prompt_token_count: usage['promptTokenCount'],
      candidates_token_count: usage['candidatesTokenCount'],
      thoughts_token_count: usage['thoughtsTokenCount'],
      cached_content_token_count: usage['cachedContentTokenCount'],
      total_token_count: usage['totalTokenCount']
    }.compact
  end
end
