# Re-queues failed AI metadata drafts. Drafts that belong to a run transcribe any pages
# that still need it (including pages whose transcription failed) before drafting again.
class AiWorkMetadata::RetryFailed < ApplicationInteractor
  include AiWorkMetadata::Lib::Common

  attr_accessor :retried_count

  def initialize(collection:, user:, drafts:)
    @collection = collection
    @user = user
    @drafts = drafts
    @retried_count = 0

    super
  end

  def perform
    check_user_permission

    @drafts.status_error.joins(:work).where(works: { collection_id: @collection.id }).find_each do |draft|
      draft.update!(status: draft.ai_work_metadata_run_id ? :new : :processing)
      AiWorkMetadata::GenerateJob.perform_later(ai_work_metadata_id: draft.id, user_id: @user.id)
      @retried_count += 1
    end
  end
end
