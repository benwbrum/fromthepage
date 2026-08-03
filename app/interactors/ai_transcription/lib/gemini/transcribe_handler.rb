class AiTranscription::Lib::Gemini::TranscribeHandler < AiTranscription::Lib::BaseTranscribeHandler
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

  USAGE_METADATA_SCHEMA_VERSION = 2

  NORMALIZED_USAGE_FIELDS = {
    'promptTokenCount' => :prompt_token_count,
    'candidatesTokenCount' => :candidates_token_count,
    'thoughtsTokenCount' => :thoughts_token_count,
    'toolUsePromptTokenCount' => :tool_use_prompt_token_count,
    'cachedContentTokenCount' => :cached_content_token_count,
    'totalTokenCount' => :total_token_count,
    'promptTokensDetails' => :prompt_tokens_details,
    'candidatesTokensDetails' => :candidates_tokens_details,
    'cacheTokensDetails' => :cache_tokens_details,
    'toolUsePromptTokensDetails' => :tool_use_prompt_tokens_details
  }.freeze

  ACCOUNTED_TOKEN_FIELDS = %i[
    prompt_token_count
    candidates_token_count
    thoughts_token_count
    tool_use_prompt_token_count
  ].freeze

  def perform
    attempt = 0
    last_error = nil

    loop do
      attempt += 1

      begin
        response = client.generate_content(payload)

        metadata = extract_usage_metadata(response)

        transcription_text, reasoning_text = extract_texts_from_response(response)

        return [transcription_text, reasoning_text, metadata, response]
      rescue => e
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
        Rails.logger.error("Gemini API error: #{sanitized_message(e)}")
        raise e
      end
    end
  rescue => e
    Rails.logger.error("Gemini API error: #{sanitized_message(e)}")
    raise e
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
          { text: @prompt },
          {
            inline_data: {
              mime_type: 'image/jpeg',
              data: encoded_image
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

  def encoded_image
    return @encoded_image if defined?(@encoded_image)
    @encoded_image = if @image_path
      Base64.strict_encode64(File.binread(@image_path))
    else
      fetch_and_encode_image(url: @image_url)
    end
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
    metadata = NORMALIZED_USAGE_FIELDS.each_with_object({}) do |(provider_key, normalized_key), normalized|
      normalized[normalized_key] = usage[provider_key] if usage.key?(provider_key)
    end

    # cachedContentTokenCount describes the cached portion of promptTokenCount,
    # rather than another mutually exclusive category, so it is deliberately not
    # included in this sum.
    metadata[:accounted_token_count] = ACCOUNTED_TOKEN_FIELDS.sum { |key| metadata[key].to_i }
    metadata[:unaccounted_token_count] = if metadata.key?(:total_token_count)
      metadata[:total_token_count] - metadata[:accounted_token_count]
    end
    metadata[:usage_metadata_schema_version] = USAGE_METADATA_SCHEMA_VERSION
    metadata[:usage_metadata_reconciliation_status] = reconciliation_status(metadata)
    metadata[:provider_usage_metadata] = usage

    metadata.compact
  end

  def reconciliation_status(metadata)
    return 'total_unavailable' unless metadata.key?(:total_token_count)
    return 'reconciled' if metadata[:unaccounted_token_count].zero?
    return 'over_accounted' if metadata[:unaccounted_token_count].negative?

    'unaccounted_tokens'
  end
end
