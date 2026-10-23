class AiTranscription::BulkCreate < ApplicationInteractor
  BATCH_SIZE = 1_000
  include AiTranscription::Lib::Common

  def initialize(collection:, user:, scope: nil, model: nil, prompt_file: nil)
    @collection = collection
    @user = user
    @scope = scope
    @model = model
    @prompt_file = prompt_file

    super
  end

  def perform
    check_user_permission

    @sanitized_model = sanitize_model
    @sanitized_prompt = build_prompt

    ai_transcription_records = []

    pages.find_each do |page|
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
        ai_transcription.model = @sanitized_model
        ai_transcription.prompt = @sanitized_prompt
        ai_transcription_records << ai_transcription
      end
    end

    AiTranscription.import! ai_transcription_records, on_duplicate_key_update: [:status, :model, :prompt], batch_size: BATCH_SIZE
  end

  private

  def pages
    return @pages if defined?(@pages)

    @pages = @collection.pages.includes(:ai_transcription)

    return @pages if @scope.nil?

    work_ids = @scope[:work_ids] || []

    @pages = @pages.where(work_id: work_ids)

    @pages
  end
end
