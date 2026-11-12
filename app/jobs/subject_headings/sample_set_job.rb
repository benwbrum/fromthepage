class SubjectHeadings::SampleSetJob < ApplicationJob
  queue_as :ai_work_metadata

  retry_on StandardError, attempts: 1

  # Creates the collection's sample set (or reuses an existing one) and queues AI metadata drafts
  # (including subject heading candidates) for its works, as "Draft sample" does on the AI settings tab.
  def perform(user_id:, collection_id:)
    user = User.find(user_id)
    collection = Collection.find(collection_id)

    started = AiWorkMetadata::StartRun.new(collection: collection, user: user, kind: :sample).call
    raise started.full_errors unless started.success?
  end
end
