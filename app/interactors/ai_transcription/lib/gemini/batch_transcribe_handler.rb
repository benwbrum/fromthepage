class AiTranscription::Lib::Gemini::BatchTranscribeHandler
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

  def initialize(ai_batch_generation:)
    @ai_batch_generation = ai_batch_generation
    @collection = @ai_batch_generation.collection

    # TODO: Add support for customizing model/prompts for batch_generate
    @model = AiTranscription::DEFAULT_MODEL
  end

  def perform
    result = client.batch_generate_content(
      {
        batch: {
          display_name: @collection.slug,
          input_config: {
            requests: {
              requests: payload
            }
          }
        }
      }
    )

    raise 'Unknown API Error' unless result['name'].present?

    @ai_batch_generation.update!(batch_key: result['name'])
  end

  private

  def payload
    return @payload if defined?(@payload)

    @payload = []

    @ai_batch_generation.ai_batch_generation_pages.includes(:page, :ai_transcription).each do |object|
      batch_hash = {
        request: {
          contents: {
            role: 'user',
            parts: [
              { text: object.ai_transcription.prompt },
              {
                inline_data: {
                  mime_type: 'image/jpeg',
                  data: fetch_and_encode_image(url: object.page.image_url_for_download)
                }
              }
            ]
          }
        },
        metadata: {
          key: "ai-transcription-#{object.ai_transcription.id}"
        }
      }

      if REASONING_MAP[@model]
        batch_hash[:request][:generation_config] = {
          thinking_config: {
            include_thoughts: true
          }
        }
      end

      @payload << batch_hash
    end

    @payload
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
end
