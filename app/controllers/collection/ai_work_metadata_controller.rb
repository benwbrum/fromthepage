class Collection::AiWorkMetadataController < CollectionController
  before_action :authorized?

  def show
    @ai_work_metadata = AiWorkMetadata.joins(:work).where(works: { collection_id: @collection.id }).find(params[:id])
    @work = @ai_work_metadata.work
  end

  def create
    @result = AiWorkMetadata::BulkCreate.new(
      collection: @collection,
      user: current_user
    ).call

    if @result.success?
      AiWorkMetadata::BulkGenerateJob.perform_later(
        collection_id: @collection.id,
        user_id: current_user.id
      )
    end

    assign_stats

    respond_to(&:turbo_stream)
  end

  private

  def assign_stats
    stats = AiWorkMetadata.stats_for_collection(@collection)

    @works_count = stats.works_count
    @ai_work_metadata_count = stats.ai_work_metadata_count
    @queued_work_metadata_count = stats.queued_count
    @finished_work_metadata_count = stats.finished_count
    @failed_work_metadata_count = stats.failed_count
    @not_started_work_metadata_count = stats.not_started_count
    @failed_ai_work_metadata = stats.failed_records
    @failed_ai_work_metadata_hidden_count = stats.failed_hidden_count
    @total_work_metadata_token_count = stats.total_token_count
  end
end
