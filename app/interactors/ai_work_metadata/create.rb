class AiWorkMetadata::Create < ApplicationInteractor
  include AiWorkMetadata::Lib::Common

  attr_accessor :ai_work_metadata

  # All AiWorkMetadata db record creation MUST go through this interactor
  # This interactor will handle sanitation of params and defaults
  # as well as permission checking to prevent abuse
  #
  # @params work: required
  #   - Work record to create ai_work_metadata for
  # @params user: required
  #   - User record to create ai_work_metadata
  #   - User must be admin OR like_owner? to create ai_work_metadata
  # @params model: optional
  #   - AI Model to be used. ex: 'gemini-3.7-flash'
  #   - defaults to `AiWorkMetadata::DEFAULT_MODEL`
  # @params retranscribe
  #   - If ai_work_metadata exists, checks if we want to regenerate a new one
  #   - default: false
  def initialize(work:, user:, model: nil, retranscribe: false)
    @work = work
    @collection = work.collection
    @user = user

    @model = model
    @retranscribe = retranscribe

    super
  end

  def perform
    check_user_permission

    raise ArgumentError, 'Collection has no metadata fields configured' unless @collection.metadata_fields.exists?

    @sanitized_model = sanitize_model
    @sanitized_prompt = build_prompt

    @ai_work_metadata = find_or_generate_ai_work_metadata
  end

  private

  def find_or_generate_ai_work_metadata
    ai_work_metadata = latest_ai_work_metadata_for_model_engine

    if ai_work_metadata.nil? || ((ai_work_metadata.status_finished? || ai_work_metadata.status_processing?) && @retranscribe)
      return AiWorkMetadata.create!(
        work_id: @work.id,
        status: :processing,
        model: @sanitized_model,
        prompt: @sanitized_prompt
      )
    elsif ai_work_metadata.status_new? || ai_work_metadata.status_error?
      ai_work_metadata.update!(
        status: :processing,
        model: @sanitized_model,
        prompt: @sanitized_prompt
      )

      return ai_work_metadata
    end

    raise StandardError, 'AI Work Metadata generation is either in progress or completed!'
  end

  def latest_ai_work_metadata_for_model_engine
    engine = AiWorkMetadata.engine_for_model(@sanitized_model)

    @work.ai_work_metadata
         .order(created_at: :desc)
         .detect { |ai_work_metadata| ai_work_metadata.engine == engine }
  end
end
