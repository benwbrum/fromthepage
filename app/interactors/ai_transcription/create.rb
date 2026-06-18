class AiTranscription::Create < ApplicationInteractor
  include AiTranscription::Lib::Common

  attr_accessor :ai_transcription

  # All AiTranscription db record creation MUST go through this interactor
  # This interactor will handle sanitation of params and defaults
  # as well as permission checking to prevent abuse
  #
  # This interactor will fail if ai_transcription record is
  #
  # @params page: required
  #   - Page record to create ai_transcription
  # @params user: required
  #   - User record to create ai_transcription
  #   - User must be admin OR can_transcribe to create ai_transcription
  # @params model: required
  #   - AI Model to be used. ex: 'gemini-3-pro-preview'
  #   - defaults to `AiTranscription::DEFAULT_MODEL`
  # @params prompt: required
  #   - Prompt `TEXT`, not `FILE` is expected
  #   - default: reads content of `lib/transcription_prompt.txt`
  # @params retranscribe
  #   - If ai_transcription exists, checks if we want to regenerate a new one
  #   - default: false
  def initialize(page:, user:, model: nil, prompt_file: nil, retranscribe: false)
    @page = page
    @work = @page.work
    @collection = @page.collection
    @user = user

    @model = model
    @prompt_file = prompt_file

    @retranscribe = retranscribe

    super
  end

  def perform
    check_user_permission

    @sanitized_model = sanitize_model
    @sanitized_prompt = build_prompt

    @ai_transcription = find_or_generate_ai_transcription
  end

  private

  def build_prompt
    return sanitize_prompt if @prompt_file.present? || !@collection.field_based
    AiTranscription::Lib::FieldBasedPromptBuilder.new(collection: @collection).build
  end

  def find_or_generate_ai_transcription
    ai_transcription = @page.ai_transcription

    if ai_transcription.nil? || ((ai_transcription.status_finished? || ai_transcription.status_processing?) && @retranscribe)
      return AiTranscription.create!(
        page_id: @page.id,
        status: :processing,
        model: @sanitized_model,
        prompt: @sanitized_prompt
      )
    elsif ai_transcription.status_new? || ai_transcription.status_error?
      ai_transcription.update!(
        status: :processing,
        model: @sanitized_model,
        prompt: @sanitized_prompt
      )

      return ai_transcription
    end

    raise StandardError, 'AI Transcription generation is either in progress or completed!'
  end
end
