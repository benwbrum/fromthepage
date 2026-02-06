class AiTranscription::BulkRetryJob < ApplicationJob
  queue_as :default

  retry_on StandardError, attempts: 1

  # TODO: Exclude user_id for lint checks on unused vars for app/jobs/**/*
  def perform(user_id:, ai_transcription_ids:)
    user = User.find(user_id)
    ai_transcriptions = AiTranscription.where(id: ai_transcription_ids)

    ai_transcriptions.each do |ai_transcription|
      AiTranscription::GenerateJob.perform_later(
        ai_transcription_id: ai_transcription.id,
        user_id: user.id
      )
    end
  end
end
