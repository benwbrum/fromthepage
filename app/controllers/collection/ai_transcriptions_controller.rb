class Collection::AiTranscriptionsController < CollectionController
  before_action :authorized?

  def edit
    @status = AiSettingsStatus.new(@collection)
  end

  def show
    @ai_transcription = AiTranscription.joins(page: :work).where(works: { collection_id: @collection.id }).find(params[:id])
    @page = @ai_transcription.page
    @work = @page.work
  end

  def create
    @result = AiTranscription::BulkCreate.new(
      collection: @collection,
      user: current_user
    ).call

    if @result.success?
      AiTranscription::BulkGenerateJob.perform_later(
        collection_id: @collection.id,
        user_id: current_user.id
      )
    end
    @status = AiSettingsStatus.new(@collection)

    respond_to(&:turbo_stream)
  end

  def update
    @result = AiTranscription::BulkRetry.new(
      collection: @collection,
      user: current_user
    ).call

    if @result.success?
      AiTranscription::BulkRetryJob.perform_later(
        ai_transcription_ids: @result.ai_transcription_ids,
        user_id: current_user.id
      )
    end
    @status = AiSettingsStatus.new(@collection)

    respond_to(&:turbo_stream)
  end
end
