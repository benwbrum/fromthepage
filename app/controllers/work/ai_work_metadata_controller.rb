class Work::AiWorkMetadataController < WorkController
  before_action :authorized?

  def show
    @ai_work_metadata = @work.ai_work_metadata.find(params[:id])
  end

  def create
    @result = AiWorkMetadata::BulkCreate.new(
      collection: @collection,
      user: current_user,
      scope: { work_ids: [@work.id] }
    ).call

    if @result.success?
      AiWorkMetadata::BulkGenerateJob.perform_later(
        collection_id: @collection.id,
        user_id: current_user.id,
        scope: { work_ids: [@work.id] }
      )
    end

    @ai_work_metadata_records = @work.ai_work_metadata.order(created_at: :desc)

    respond_to(&:turbo_stream)
  end
end
