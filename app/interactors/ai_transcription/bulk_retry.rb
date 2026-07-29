class AiTranscription::BulkRetry < ApplicationInteractor
  include AiTranscription::Lib::Common

  BATCH_SIZE = 1_000
  attr_accessor :ai_transcription_ids

  def initialize(collection:, user:, scope: nil)
    @collection = collection
    @user = user
    @scope = scope
    @ai_transcription_ids = []

    super
  end

  def perform
    check_user_permission

    @sanitized_model = sanitize_model
    @sanitized_prompt = build_prompt

    ai_transcription_records = []

    pages.find_each do |page|
      ai_transcription = page.ai_transcription

      next unless ai_transcription.status_error?

      ai_transcription.status = :processing
      ai_transcription.model = @sanitized_model
      ai_transcription.prompt = @sanitized_prompt
      ai_transcription_records << ai_transcription
    end

    AiTranscription.import! ai_transcription_records, on_duplicate_key_update: [:status, :model, :prompt], batch_size: BATCH_SIZE

    @ai_transcription_ids = ai_transcription_records.pluck(:id)
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
