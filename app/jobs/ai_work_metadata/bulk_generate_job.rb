class AiWorkMetadata::BulkGenerateJob < ApplicationJob
  queue_as :ai_work_metadata

  retry_on StandardError, attempts: 1

  def perform(user_id:, collection_id:, scope: nil)
    user = User.find(user_id)
    collection = Collection.find(collection_id)
    works = collection.works.includes(:ai_work_metadata)

    if scope.present?
      works = works.where(id: scope[:work_ids] || [])
    end

    ai_work_metadata_records = works.flat_map(&:ai_work_metadata)

    ai_work_metadata_records.each do |ai_work_metadata|
      next unless ai_work_metadata.status_processing? || ai_work_metadata.status_new?

      AiWorkMetadata::GenerateJob.perform_later(
        ai_work_metadata_id: ai_work_metadata.id,
        user_id: user.id
      )
    end
  end
end
