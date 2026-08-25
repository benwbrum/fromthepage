class Collection::AiTranscriptionsController < CollectionController
  before_action :authorized?

  def edit
    calculate_counts
  end

  def show
    @ai_transcription = AiTranscription.joins(page: :work).where(works: { collection_id: @collection.id }).find(params[:id])
    @page = @ai_transcription.page
    @work = @page.work
  end

  def create
    @result = AiTranscription::EnqueueBatch.new(
      collection: @collection,
      user: current_user
    ).call

    calculate_counts if @result.success?

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

  def failed
    latest_ai_transcriptions = AiTranscription
      .joins("INNER JOIN (#{latest_per_page.to_sql}) latest ON latest.id = ai_transcriptions.id")

    @failed_ai_transcriptions = latest_ai_transcriptions
      .where(status: :error)
      .includes(page: :work)
      .order(updated_at: :desc)
      .limit(AiTranscription::MAX_FAILED_ERRORS)

    @failed_transcriptions_count = @collection.pages.where(cached_ai_status: :error).count

    @failed_ai_transcriptions_hidden_count = [0, @failed_transcriptions_count - @failed_ai_transcriptions.size].max

    render turbo_stream: turbo_stream.replace('failed_transcriptions', partial: 'failed')
  end

  def tokens
    @total_token_count = AiTranscription
      .joins("INNER JOIN (#{latest_per_page.to_sql}) latest ON latest.id = ai_transcriptions.id")
      .where(status: :finished)
      .sum("COALESCE(JSON_EXTRACT(metadata, '$.prompt_token_count'), 0) + COALESCE(JSON_EXTRACT(metadata, '$.candidates_token_count'), 0) + COALESCE(JSON_EXTRACT(metadata, '$.thoughts_token_count'), 0)")

    render turbo_stream: turbo_stream.replace('tokens_count', partial: 'token')
  end

  private

  def calculate_counts
    @works_count = @collection.works.count
    @pages_count = @collection.pages.count

    status_counts = @collection.pages.group(:cached_ai_status).count

    @queued_transcriptions_count =
      status_counts['new'].to_i +
      status_counts['queued'].to_i +
      status_counts['processing'].to_i
    @finished_transcriptions_count = status_counts['finished'].to_i
    @failed_transcriptions_count = status_counts['error'].to_i
    @not_started_transcriptions_count = status_counts['not_started'].to_i
  end

  def latest_per_page
    @latest_per_page ||= AiTranscription
      .where(page_id: @collection.pages.select(:id))
      .select('MAX(id) AS id')
      .group(:page_id)
  end
end
