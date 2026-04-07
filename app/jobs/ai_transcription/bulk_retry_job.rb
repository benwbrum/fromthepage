class AiTranscription::BulkRetryJob < ApplicationJob
  limits_concurrency key: ->(user_id:, ai_transcription_ids:) { "bulk_retry:#{ai_transcription_ids}" }, duration: 2.hours

  queue_as :ai_transcriptions

  retry_on StandardError, attempts: 1

  # TODO: Exclude user_id for lint checks on unused vars for app/jobs/**/*
  def perform(user_id:, ai_transcription_ids:)
    user = User.find(user_id)
    ai_transcriptions = AiTranscription.where(id: ai_transcription_ids)

    ai_transcriptions.each do |ai_transcription|
      AiTranscription::GenerateJob.perform_later(
        ai_transcription_id: ai_transcription.id,
        user_id: user.id,
        page_id: ai_transcription.page_id
      )
    end
  end
end
