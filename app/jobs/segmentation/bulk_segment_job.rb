class Segmentation::BulkSegmentJob < ApplicationJob
  queue_as :ai_transcriptions

  retry_on StandardError, attempts: 1

  def perform(work_id:, collection_id:, user_id:)
    work = Work.find(work_id)
    collection = Collection.find(collection_id)
    user = User.find(user_id)

    work.pages.order(:position).each do |page|
      # First page is always the start of something; skip analyzing it
      if page.position == 1
        page.update_column(:is_first_page_candidate, false)
        next
      end

      begin
        Segmentation::Generate.new(page: page).perform
      rescue => e
        Rails.logger.error("Segmentation failed for page #{page.id}: #{e.message}")
      end
    end

    UserMailer.segmentation_finished(user, work, collection).deliver_later
  end
end
