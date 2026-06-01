class AiTranscription::BatchGenerateJob < ApplicationJob
  queue_as :ai_transcriptions

  retry_on StandardError, attempts: 1

  limits_concurrency to: 1,
                     key: ->(args) {
                       work_ids = Array(args[:scope]&.dig(:work_ids)).sort.join('-')

                       "ai-batch-generate-collection-#{args[:collection_id]}-#{work_ids}"
                     },
                     duration: 3.hours,
                     on_conflict: :discard

  def perform(user_id:, collection_id:, scope: nil)
    user = User.find(user_id)
    collection = Collection.find(collection_id)

    result = AiTranscription::BatchGenerate.new(
      collection: collection,
      user: user,
      scope: scope
    ).call

    return if result.success?

    raise result.full_errors
  end
end
