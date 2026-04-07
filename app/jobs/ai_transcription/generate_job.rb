class AiTranscription::GenerateJob < ApplicationJob
  limits_concurrency key: ->(user_id:, ai_transcription_id:, page_id:) { "generate:#{page_id}" }, duration: 2.hours

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
  #
  # @params page_id
  #   - valid page record id to be used for concurrency key
  def perform(user_id:, ai_transcription_id:, page_id:)
    ai_transcription = AiTranscription.find(ai_transcription_id)
    user = User.find(user_id)
    collection = ai_transcription.page.collection

    unless user.admin? || user.like_owner?(collection)
      ai_transcription.update!(status: :error)

      raise ArgumentError, 'User has no permission to create AiTranscription on this page'
    end

    result = AiTranscription::Generate.new(ai_transcription: ai_transcription).call

    if result.success?
      result.ai_transcription.update!(status: :finished)
    else
      result.ai_transcription.update!(status: :error)

      raise result.full_errors
    end
  end
end
