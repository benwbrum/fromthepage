class Work::AiTranscriptionsController < WorkController
  before_action :authorized?

  def edit
    calculate_counts
  end

  def create
    @result = AiTranscription::BulkCreate.new(
      collection: @collection,
      user: current_user,
      scope: { work_ids: [@work.id] }
    ).call

    if @result.success?
      AiTranscription::BulkGenerateJob.perform_later(
        collection_id: @collection.id,
        user_id: current_user.id,
        scope: { work_ids: [@work.id] }
      )

      calculate_counts
    end

    respond_to(&:turbo_stream)
  end

  def update
    @result = AiTranscription::BulkRetry.new(
      collection: @collection,
      user: current_user,
      scope: { work_ids: [@work.id] }
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
      .where(page_id: @work.pages.select(:id))
      .select('MAX(id) AS id')
      .group(:page_id)

    latest_ai_transcriptions = AiTranscription
      .joins("INNER JOIN (#{latest_per_page.to_sql}) latest ON latest.id = ai_transcriptions.id")

    ai_transcriptions_count = latest_ai_transcriptions
      .group(:status)
      .count

    @pages_count = @work.pages.count
    @ai_transcriptions_count = latest_per_page.to_a.size
    @queued_transcriptions_count =
      ai_transcriptions_count['new'].to_i +
      ai_transcriptions_count['queued'].to_i +
      ai_transcriptions_count['processing'].to_i

    @finished_transcriptions_count = ai_transcriptions_count['finished'].to_i
    @failed_transcriptions_count = ai_transcriptions_count['error'].to_i
    @not_started_transcriptions_count = @pages_count - @ai_transcriptions_count

    @failed_ai_transcriptions = latest_ai_transcriptions
      .where(status: :error)
      .includes(:page)
      .order(updated_at: :desc)
      .limit(AiTranscription::MAX_FAILED_ERRORS)
    @failed_ai_transcriptions_hidden_count = [@failed_transcriptions_count - @failed_ai_transcriptions.size, 0].max

    @total_token_count = latest_ai_transcriptions
      .where(status: :finished)
      .sum("COALESCE(JSON_EXTRACT(metadata, '$.prompt_token_count'), 0) + COALESCE(JSON_EXTRACT(metadata, '$.candidates_token_count'), 0) + COALESCE(JSON_EXTRACT(metadata, '$.thoughts_token_count'), 0)")
  end
end
