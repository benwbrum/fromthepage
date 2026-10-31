class SubjectHeadings::SampleSetJob < ApplicationJob
  queue_as :ai_work_metadata

  retry_on StandardError, attempts: 1

  # Creates the collection's "Subject Heading Sample Set" document set and queues AI metadata drafts
  # (including subject heading candidates) for its works.
  def perform(user_id:, collection_id:)
    user = User.find(user_id)
    collection = Collection.find(collection_id)

    sample_set = SubjectHeadings::CreateSampleSet.new(collection: collection, user: user).call
    raise sample_set.full_errors unless sample_set.success?

    scope = { work_ids: sample_set.document_set.work_ids }
    drafts = AiWorkMetadata::BulkCreate.new(collection: collection, user: user, scope: scope,
                                            model: AiWorkMetadata::SUBJECT_HEADING_MODEL).call
    raise drafts.full_errors unless drafts.success?

    AiWorkMetadata::BulkGenerateJob.perform_later(user_id: user.id, collection_id: collection.id, scope: scope)
  end
end
