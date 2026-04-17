class Collection::AiTranscriptionsController < CollectionController
  before_action :authorized?

  def edit
    calculate_counts
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

  private

  def calculate_counts
    latest_per_page = AiTranscription
      .where(page_id: @collection.pages.select(:id))
      .select('MAX(id) AS id')
      .group(:page_id)

    ai_transcriptions_count = AiTranscription
      .joins("INNER JOIN (#{latest_per_page.to_sql}) latest ON latest.id = ai_transcriptions.id")
      .group(:status)
      .count

    @works_count = @collection.works.count
    @pages_count = @collection.pages.count
    @ai_transcriptions_count = latest_per_page.to_a.size
    @queued_transcriptions_count =
      ai_transcriptions_count['new'].to_i +
      ai_transcriptions_count['queued'].to_i +
      ai_transcriptions_count['processing'].to_i

    @finished_transcriptions_count = ai_transcriptions_count['finished'].to_i
    @failed_transcriptions_count = ai_transcriptions_count['error'].to_i
    @not_started_transcriptions_count = @pages_count - @ai_transcriptions_count

    @total_token_count = AiTranscription
      .joins("INNER JOIN (#{latest_per_page.to_sql}) latest ON latest.id = ai_transcriptions.id")
      .where(status: :finished)
      .sum("COALESCE(JSON_EXTRACT(metadata, '$.prompt_token_count'), 0) + COALESCE(JSON_EXTRACT(metadata, '$.candidates_token_count'), 0) + COALESCE(JSON_EXTRACT(metadata, '$.thoughts_token_count'), 0)")
  end
end
