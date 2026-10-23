class Work::AiWorkMetadataController < WorkController
  before_action :authorized?
  before_action :require_ai_work_metadata_feature, only: :create

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

  private

  def require_ai_work_metadata_feature
    head :not_found unless helpers.ai_work_metadata_available?(@collection)
  end
end
