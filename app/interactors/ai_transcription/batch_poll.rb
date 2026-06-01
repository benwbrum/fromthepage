class AiTranscription::BatchPoll < ApplicationInteractor
  POLL_INTERVAL = 10.minutes

  # Follows key (model_name) value (version)
  # Add custom handling here if the model you are using
  # does not use `v1`
  VERSION_MAP = {
    'gemini-3-pro-preview' => 'v1beta',
    'gemini-3.1-pro-preview' => 'v1beta',
    'gemini-3-flash-preview' => 'v1beta'
  }.freeze

  def initialize(user:, ai_batch_generation:)
    @user = user
    @ai_batch_generation = ai_batch_generation

    # TODO: Add support for customizing model/prompts for batch_generate
    @model = AiTranscription::DEFAULT_MODEL

    super
  end

  def perform
    return unless @ai_batch_generation.status_processing?

    response = client.batch(@ai_batch_generation.batch_key)

    state = response.dig('metadata', 'state')

    case state
    when 'BATCH_STATE_SUCCEEDED', 'JOB_STATE_SUCCEEDED'
      handle_success(response)
      @ai_batch_generation.update!(status: :finished)
    when 'BATCH_STATE_FAILED', 'JOB_STATE_FAILED', 'BATCH_STATE_CANCELLED', 'JOB_STATE_CANCELLED', 'BATCH_STATE_EXPIRED', 'JOB_STATE_EXPIRED'
      @ai_batch_generation.update!(status: :error)
    else
      AiTranscription::BatchPollJob.set(wait: POLL_INTERVAL).perform_later(
        user_id: @user.id,
        ai_batch_generation_id: @ai_batch_generation.id
      )
    end
  end

  private

  def handle_success(response)
    batch_map = {}
    response_batches = client.batch_responses(response).each do |current_response|
      key = current_response.dig('metadata', 'key')
      batch_map[key] = current_response.dig('response')
    end

    @ai_batch_generation.ai_batch_generation_pages.find_each do |object|
      page = object.page
      ai_transcription = object.ai_transcription
      collection = page.collection

      key = "ai-transcription-#{ai_transcription.id}"
      current_response = batch_map[key]

      if current_response.nil?
        ai_transcription.update!(status: :error)
        page.update!(cached_ai_status: :error)
      else
        metadata = extract_usage_metadata(current_response)
        source_text, reasoning = extract_texts_from_response(current_response)

        if collection.field_based
          handle_field_based_response(ai_transcription, page, source_text, reasoning, metadata)
        else
          handle_standard_response(ai_transcription, page, source_text, reasoning, metadata, current_response)
        end
      end
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

  def handle_standard_response(ai_transcription, page, source_text, reasoning, metadata, response)
    ai_transcription.source_text = source_text
    ai_transcription.reasoning = reasoning
    ai_transcription.metadata = metadata

    if ai_transcription.source_text.present? || ai_transcription.reasoning.present?
      ai_transcription.status = :finished
      page.cached_ai_status = :finished
    else
      ai_transcription.status = :error
      page.cached_ai_status = :error
    end

    ai_transcription.save!
    page.save!
  end

  def handle_field_based_response(ai_transcription, page, source_text, reasoning, metadata)
    validator = AiTranscription::Lib::FieldBasedResponseValidator.new(
      collection: page.collection,
      response_text: source_text
    )

    if validator.valid?
      ai_transcription.update!(
        transcription_json: validator.parsed_json,
        reasoning: reasoning,
        metadata: metadata,
        status: :finished
      )
      page.update!(cached_ai_status: :finished)
    else
      ai_transcription.update!(
        source_text: source_text,
        reasoning: reasoning,
        metadata: metadata,
        status: :error
      )
      page.update!(cached_ai_status: :error)
    end
  end
end
