class AiWorkMetadata::Lib::OpenAi::GenerateHandler
  MAX_RETRY = 5
  RETRYABLE_STATUSES = [429, 500, 502, 503, 529].freeze

  def initialize(prompt:, model:)
    @prompt = prompt
    @model = model
  end

  def perform
    attempt = 0

    loop do
      attempt += 1

      begin
        response = client.chat(parameters: payload)

        metadata_text, reasoning_text = extract_texts_from_response(response)
        metadata = extract_usage_metadata(response)

        return [metadata_text, reasoning_text, metadata, response]
      rescue Faraday::Error => e
        status = e.response.is_a?(Hash) ? e.response[:status] : nil

        if RETRYABLE_STATUSES.include?(status) && attempt <= MAX_RETRY
          delay = 2**attempt
          Rails.logger.warn("OpenAI API error #{status} (attempt #{attempt}/#{MAX_RETRY}). Retrying in #{delay} seconds...")

          sleep(delay)
          next
        end

        Rails.logger.error("OpenAI API error: #{sanitized_message(e)}")
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

    @api_key = ENV['OPENAI_ACCESS_TOKEN']

    raise ArgumentError, 'OPENAI_ACCESS_TOKEN environment variable is not set' if @api_key.blank?

    @api_key
  end

  def client
    @client ||= ::OpenAI::Client.new(access_token: api_key)
  end

  def payload
    return @payload if defined?(@payload)

    @payload = {
      model: @model,
      messages: [
        { role: 'user', content: @prompt }
      ]
    }
  end

  def extract_texts_from_response(response)
    message = response.dig('choices', 0, 'message') || {}

    metadata_text = message['content'].to_s.strip
    reasoning_text = message['reasoning_content'].to_s.strip

    [metadata_text, reasoning_text]
  end

  def extract_usage_metadata(response)
    usage = response['usage'] || {}

    {
      prompt_token_count: usage['prompt_tokens'],
      candidates_token_count: usage['completion_tokens'],
      total_token_count: usage['total_tokens']
    }.compact
  end
end
