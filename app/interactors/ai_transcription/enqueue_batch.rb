class AiTranscription::EnqueueBatch < ApplicationInteractor
  attr_accessor :ai_batch_generation
  BATCH_SIZE = 10_000

  def initialize(collection:, user:, scope: nil)
    @collection = collection
    @user = user
    @scope = scope

    super
  end

  def perform
    @pages = @collection.pages.where(
      cached_ai_status: [:not_started]
    )

    if @scope.present?
      @pages = @pages.where(work_id: @scope[:work_ids] || [])
    end

    @pages.update_all(cached_ai_status: :processing)

    AiTranscription::BatchGenerateJob.perform_later(
      user_id: @user.id,
      collection_id: @collection.id,
      scope: @scope
    )
  end
end
