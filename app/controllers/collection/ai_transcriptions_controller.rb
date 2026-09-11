class Collection::AiTranscriptionsController < CollectionController
  before_action :authorized?

  def edit
    calculate_counts
    assign_work_metadata_stats
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

  def assign_work_metadata_stats
    stats = AiWorkMetadata.stats_for_collection(@collection)

    @ai_work_metadata_count = stats.ai_work_metadata_count
    @queued_work_metadata_count = stats.queued_count
    @finished_work_metadata_count = stats.finished_count
    @failed_work_metadata_count = stats.failed_count
    @not_started_work_metadata_count = stats.not_started_count
    @failed_ai_work_metadata = stats.failed_records
    @failed_ai_work_metadata_hidden_count = stats.failed_hidden_count
    @total_work_metadata_token_count = stats.total_token_count
  end

  def calculate_counts
    collection_pages = Page
      .joins(:work)
      .where(works: { collection_id: @collection.id })
      .reorder(nil)

    latest_per_page = AiTranscription
      .where(page_id: collection_pages.select(:id))
      .select('MAX(id) AS id')
      .group(:page_id)

    latest_ai_transcriptions = AiTranscription
      .joins("INNER JOIN (#{latest_per_page.to_sql}) latest ON latest.id = ai_transcriptions.id")

    ai_transcriptions_count, new_transcriptions_count, queued_transcriptions_count,
      processing_transcriptions_count, finished_transcriptions_count, failed_transcriptions_count =
      latest_ai_transcriptions.pick(
        Arel.sql('COUNT(*)'),
        Arel.sql("SUM(CASE WHEN ai_transcriptions.status = 'new' THEN 1 ELSE 0 END)"),
        Arel.sql("SUM(CASE WHEN ai_transcriptions.status = 'queued' THEN 1 ELSE 0 END)"),
        Arel.sql("SUM(CASE WHEN ai_transcriptions.status = 'processing' THEN 1 ELSE 0 END)"),
        Arel.sql("SUM(CASE WHEN ai_transcriptions.status = 'finished' THEN 1 ELSE 0 END)"),
        Arel.sql("SUM(CASE WHEN ai_transcriptions.status = 'error' THEN 1 ELSE 0 END)")
      )

    @works_count = @collection.works.count
    @pages_count = collection_pages.count
    @ai_transcriptions_count = ai_transcriptions_count.to_i
    @queued_transcriptions_count =
      new_transcriptions_count.to_i +
      queued_transcriptions_count.to_i +
      processing_transcriptions_count.to_i

    @finished_transcriptions_count = finished_transcriptions_count.to_i
    @failed_transcriptions_count = failed_transcriptions_count.to_i
    @not_started_transcriptions_count = @pages_count - @ai_transcriptions_count

    @failed_ai_transcriptions = latest_ai_transcriptions
      .where(status: :error)
      .includes(page: :work)
      .order(updated_at: :desc)
      .limit(AiTranscription::MAX_FAILED_ERRORS)
    @failed_ai_transcriptions_hidden_count = [0, @failed_transcriptions_count - @failed_ai_transcriptions.size].max

    @total_token_count = latest_ai_transcriptions
      .where(status: :finished)
      .sum("COALESCE(JSON_EXTRACT(metadata, '$.prompt_token_count'), 0) + COALESCE(JSON_EXTRACT(metadata, '$.candidates_token_count'), 0) + COALESCE(JSON_EXTRACT(metadata, '$.thoughts_token_count'), 0)")
  end
end
