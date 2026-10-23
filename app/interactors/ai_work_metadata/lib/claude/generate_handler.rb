class AiWorkMetadata::Lib::Claude::GenerateHandler
  MAX_RETRY = 5

  REASONING_MODELS = %w[
    claude-fable-5
    claude-opus-4-8
    claude-opus-4-7
    claude-opus-4-6
    claude-sonnet-4-6
  ].freeze

  def initialize(prompt:, model:)
    @prompt = prompt
    @model = model
  end

  def perform
    attempt = 0

    loop do
      attempt += 1

      begin
        response = client.messages.create(**payload)

        metadata_text, reasoning_text = extract_texts_from_response(response)
        metadata = extract_usage_metadata(response)
        return [metadata_text, reasoning_text, metadata, response]
      rescue Anthropic::Errors::APIStatusError => e
        if e.status == 529 && attempt <= MAX_RETRY
          delay = 2**attempt
          Rails.logger.warn("Anthropic API overloaded (attempt #{attempt}/#{MAX_RETRY}). Retrying in #{delay} seconds...")
          sleep(delay)
          next
        end
        Rails.logger.error("Anthropic API error: #{e.message}")
        raise
      rescue => e
        Rails.logger.error("Anthropic API error: #{e.message}")
        raise
      end
    end
  end

  private

  def api_key
    return @api_key if defined?(@api_key)
    @api_key = ENV['ANTHROPIC_API_KEY']
    raise ArgumentError, 'ANTHROPIC_API_KEY environment variable is not set' if @api_key.blank?
    @api_key
  end

  def client
    @client ||= Anthropic::Client.new(api_key: api_key)
  end

  def payload
    return @payload if defined?(@payload)

    @payload = {
      model: @model,
      max_tokens: 16_000,
      messages: [{
        role: 'user',
        content: [
          { type: 'text', text: @prompt }
        ]
      }]
    }

    if REASONING_MODELS.any? { |m| @model.start_with?(m) }
      @payload[:thinking] = { type: 'adaptive', display: 'summarized' }
    end

    @payload
  end

  def extract_texts_from_response(response)
    metadata_parts = []
    reasoning_parts = []

    response.content.each do |block|
      case block.type
      when :thinking
        reasoning_parts << block.thinking
      when :text
        metadata_parts << block.text
      end
    end

    [metadata_parts.join('').strip, reasoning_parts.join('').strip]
  end

  def extract_usage_metadata(response)
    {
      prompt_token_count: response.usage.input_tokens,
      candidates_token_count: response.usage.output_tokens,
      total_token_count: response.usage.input_tokens + response.usage.output_tokens
    }
  end
end
