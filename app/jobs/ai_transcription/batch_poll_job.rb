class AiTranscription::BatchPollJob < ApplicationJob
  queue_as :ai_transcriptions

  retry_on StandardError, attempts: 1

  limits_concurrency to: 1,
                     key: ->(user_id:, ai_batch_generation_id:) { "ai-batch-poll-#{ai_batch_generation_id}" },
                     duration: 10.minutes,
                     on_conflict: :discard

  def perform(user_id:, ai_batch_generation_id:)
    user = User.find(user_id)
    ai_batch_generation = AiBatchGeneration.find(ai_batch_generation_id)

    result = AiTranscription::BatchPoll.new(
      user: user,
      ai_batch_generation: ai_batch_generation
    ).call

    return if result.success?

    raise result.full_errors
  end
end
