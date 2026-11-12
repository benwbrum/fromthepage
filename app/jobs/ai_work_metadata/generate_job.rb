class AiWorkMetadata::GenerateJob < ApplicationJob
  queue_as :ai_work_metadata

  retry_on StandardError, attempts: 1

  # All AI Work Metadata generation calls must go through this job
  # This job expects a valid ai_work_metadata db record to exist
  # For initializing AiWorkMetadata objects, use AiWorkMetadata::Create
  #
  # Drafts launched from the collection AI settings tab belong to an AiWorkMetadataRun. Those start
  # once the collection is AI-transcribed; the prompt is rebuilt here from the current text with the
  # run's reviewed examples.
  #
  # @params ai_work_metadata_id
  #   - valid ai_work_metadata record id to be used for generation
  def perform(user_id:, ai_work_metadata_id:)
    ai_work_metadata = AiWorkMetadata.find(ai_work_metadata_id)
    user = User.find(user_id)
    collection = ai_work_metadata.work.collection

    unless user.admin? || user.like_owner?(collection)
      error_message = 'User has no permission to create AiWorkMetadata on this work'
      store_error!(ai_work_metadata, error_message)

      raise ArgumentError, error_message
    end

    if (run = ai_work_metadata.ai_work_metadata_run)
      prompt = AiWorkMetadata::Lib::PromptBuilder.new(work: ai_work_metadata.work, examples: run.examples).build
      ai_work_metadata.update!(status: :processing, prompt: prompt)
    end

    result = AiWorkMetadata::Generate.new(ai_work_metadata: ai_work_metadata).call

    if result.success?
      result.ai_work_metadata.update!(status: :finished)
    else
      store_error!(result.ai_work_metadata, result.full_errors.message)

      raise result.full_errors
    end
  end

  private

  def store_error!(ai_work_metadata, error_message)
    metadata = ai_work_metadata.metadata.is_a?(Hash) ? ai_work_metadata.metadata.dup : {}
    metadata['error_message'] = AiTranscription::Lib::ErrorMessageSanitizer.sanitize(error_message)
    ai_work_metadata.update!(status: :error, metadata: metadata)
  end
end
