class AiTranscription::BulkCreate < ApplicationInteractor
  BATCH_SIZE = 1_000
  include AiTranscription::Lib::Common

  def initialize(collection:, user:, model: nil, prompt_file: nil)
    @collection = collection
    @user = user
    @model = model
    @prompt_file = prompt_file

    super
  end

  def perform
    check_lock

    begin
      check_user_permission

      @sanitized_model = sanitize_model
      @sanitized_prompt = sanitize_prompt

      ai_transcription_records = []

      @collection.pages.includes(:ai_transcription).find_each do |page|
        ai_transcription = page.ai_transcription

        if ai_transcription.nil?
          ai_transcription_records << AiTranscription.new(
            page_id: page.id,
            model: @sanitized_model,
            prompt: @sanitized_prompt,
            status: :processing
          )
        elsif ai_transcription.status_new?
          ai_transcription.status = :processing
          ai_transcription_records << ai_transcription
        end
      end

      AiTranscription.import! ai_transcription_records, on_duplicate_key_update: [:status], batch_size: BATCH_SIZE
    ensure
      release_lock
    end
  end

  def lock_name
    @lock_name ||= "bulk_create:#{@collection.id}"
  end

  def lock
    @lock ||= ActiveRecord::Base.connection.select_value(
      "SELECT GET_LOCK('#{lock_name}', 0)"
    )
  end

  def check_lock
    return if lock == 1

    raise ArgumentError, 'Job is already running'
  end

  def release_lock
    ActiveRecord::Base.connection.execute("DO RELEASE_LOCK('#{lock_name}')")
  end
end
