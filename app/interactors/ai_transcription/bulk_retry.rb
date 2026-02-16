class AiTranscription::BulkRetry < ApplicationInteractor
  include AiTranscription::Lib::Common

  BATCH_SIZE = 1_000
  attr_accessor :ai_transcription_ids

  def initialize(collection:, user:)
    @collection = collection
    @user = user
    @ai_transcription_ids = []

    super
  end

  def perform
    check_user_permission

    ai_transcription_records = []

    @collection.pages.includes(:ai_transcription).find_each do |page|
      ai_transcription = page.ai_transcription

      next unless ai_transcription.status_error?

      ai_transcription.status = :processing
      ai_transcription_records << ai_transcription
    end

    AiTranscription.import! ai_transcription_records, on_duplicate_key_update: [:status], batch_size: BATCH_SIZE

    @ai_transcription_ids = ai_transcription_records.pluck(:id)
  end
end
