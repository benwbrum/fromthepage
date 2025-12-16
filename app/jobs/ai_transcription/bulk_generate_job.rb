class AiTranscription::BulkGenerateJob < ApplicationJob
  queue_as :default

  retry_on StandardError, attempts: 1

  # TODO: Exclude user_id for lint checks on unused vars for app/jobs/**/*
  def perform(user_id:, collection_id:)
    user = User.find(user_id)
    collection = Collection.find(collection_id)
    ai_transcriptions = collection.pages
                                  .includes(:ai_transcription)
                                  .map(&:ai_transcription)
                                  .compact

    ai_transcriptions.each do |ai_transcription|
      next unless ai_transcription.status_processing? || ai_transcription.status_new?

      AiTranscription::GenerateJob.perform_later(
        ai_transcription_id: ai_transcription.id,
        user_id: user.id
      )
    end
  end
end
