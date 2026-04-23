class Work::AiTranscriptionsController < WorkController
  before_action :authorized?

  def create
    @result = AiTranscription::BulkCreate.new(
      collection: @collection,
      user: current_user,
      scope: { work_ids: [@work.id] }
    ).call

    if @result.success?
      AiTranscription::BulkGenerateJob.perform_later(
        collection_id: @collection.id,
        user_id: current_user.id
      )

      calculate_counts
    end

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

      calculate_counts
    end

    respond_to(&:turbo_stream)
  end
end
