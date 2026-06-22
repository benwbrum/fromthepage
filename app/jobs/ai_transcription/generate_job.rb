class AiTranscription::GenerateJob < ApplicationJob
  queue_as :ai_transcriptions

  retry_on StandardError, attempts: 1

  # TODO: Exclude user_id for lint checks on unused vars for app/jobs/**/*
  #
  # All AI Transcription generation call must go through this job
  # This job expects valid ai_transcription db record to exist
  # For initializing AiTranscription object, use AiTranscription::Create
  #
  # @params ai_transcription_id
  #   - valid ai_transcription record id to be used for generation
  def perform(user_id:, ai_transcription_id:)
    ai_transcription = AiTranscription.find(ai_transcription_id)
    user = User.find(user_id)
    collection = ai_transcription.page.collection

    unless user.admin? || user.like_owner?(collection)
      error_message = 'User has no permission to create AiTranscription on this page'
      store_error!(ai_transcription, error_message)

      raise ArgumentError, error_message
    end

    result = AiTranscription::Generate.new(ai_transcription: ai_transcription).call

    if result.success?
      result.ai_transcription.update!(status: :finished)
    else
      store_error!(result.ai_transcription, result.full_errors.message)

      raise result.full_errors
    end
  end

  private

  def store_error!(ai_transcription, error_message)
    ai_transcription.class.transaction do
      ai_transcription.lock!
      metadata = ai_transcription.metadata.is_a?(Hash) ? ai_transcription.metadata.dup : {}
      metadata['error_message'] = error_message
      ai_transcription.update!(status: :error, metadata: metadata)
    end
  end
end
