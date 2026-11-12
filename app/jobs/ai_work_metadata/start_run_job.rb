class AiWorkMetadata::StartRunJob < ApplicationJob
  queue_as :ai_work_metadata

  WAIT = 30.seconds

  # Waits for the collection's AI transcription to finish, then chooses the run's works
  # (the sample set, for a sample run) and queues their AI metadata drafts.
  def perform(user_id:, run_id:)
    run = AiWorkMetadataRun.find_by(id: run_id)
    return unless run&.waiting?

    collection = run.collection
    transcription = AiWorkMetadata::Lib::CollectionTranscription
    # Pages added while waiting are transcribed too
    transcription.launch!(collection, run.user) unless transcription.in_progress?(collection)

    if transcription.complete?(collection)
      AiWorkMetadata::StartRun.begin!(run)
    else
      self.class.set(wait: WAIT).perform_later(user_id: user_id, run_id: run.id)
    end
  end
end
