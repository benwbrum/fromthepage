# Everything the collection AI settings tab shows: AI transcription progress (including pages
# transcribed inside AI metadata draft jobs) and the AI metadata draft sample/remainder flow.
class AiSettingsStatus
  SampleRow = Struct.new(:work, :draft, :pages_count, :needs_transcription, keyword_init: true) do
    def status
      draft&.sample_status || 'queued'
    end
  end

  attr_reader :collection

  def initialize(collection)
    @collection = collection
  end

  # --- AI transcription (counted in pages) ---

  def pages_count
    @pages_count ||= collection_pages.count
  end

  def transcription_counts
    @transcription_counts ||= begin
      total, in_progress, finished, failed = latest_ai_transcriptions.pick(
        Arel.sql('COUNT(*)'),
        Arel.sql("SUM(CASE WHEN ai_transcriptions.status IN ('new', 'queued', 'processing') THEN 1 ELSE 0 END)"),
        Arel.sql("SUM(CASE WHEN ai_transcriptions.status = 'finished' THEN 1 ELSE 0 END)"),
        Arel.sql("SUM(CASE WHEN ai_transcriptions.status = 'error' THEN 1 ELSE 0 END)")
      )
      { finished: finished.to_i, in_progress: in_progress.to_i, failed: failed.to_i,
        not_started: pages_count - total.to_i }
    end
  end

  def transcription_running?
    transcription_counts[:in_progress].positive?
  end

  def failed_transcriptions
    @failed_transcriptions ||= latest_ai_transcriptions.status_error.includes(page: :work)
                                                       .order(updated_at: :desc).limit(AiTranscription::MAX_FAILED_ERRORS)
  end

  def failed_transcriptions_hidden_count
    [0, transcription_counts[:failed] - failed_transcriptions.size].max
  end

  def transcription_token_count
    latest_ai_transcriptions.status_finished.sum(
      "COALESCE(JSON_EXTRACT(metadata, '$.prompt_token_count'), 0) + COALESCE(JSON_EXTRACT(metadata, '$.candidates_token_count'), 0) + COALESCE(JSON_EXTRACT(metadata, '$.thoughts_token_count'), 0)"
    )
  end

  # --- AI metadata draft (counted in works) ---

  def works_count
    @works_count ||= collection.works.count
  end

  def works_without_ai_transcription_count
    @works_without_ai_transcription_count ||= collection.works.where(id: pages_needing_transcription.select(:work_id)).count
  end

  def sample_set
    return @sample_set if defined?(@sample_set)

    @sample_set = AiWorkMetadata::StartRun.sample_set(collection)
  end

  def small_collection?
    works_count <= SubjectHeadings::CreateSampleSet::SIZE
  end

  def sample_size
    sample_run ? sample_rows.size : [works_count, SubjectHeadings::CreateSampleSet::SIZE].min
  end

  def sample_run
    @sample_run ||= collection.ai_work_metadata_runs.where(kind: 'sample').order(:id).last
  end

  # A run waiting for the collection's AI transcription to finish before drafting
  def waiting_run
    return @waiting_run if defined?(@waiting_run)

    @waiting_run = collection.ai_work_metadata_runs.where(started_at: nil).order(:id).last
  end

  # Pages still to be AI-transcribed before a waiting run can start
  def pages_left_to_transcribe
    transcription_counts[:not_started] + transcription_counts[:in_progress]
  end

  def remainder_run
    @remainder_run ||= collection.ai_work_metadata_runs.where(kind: %w[remainder all]).order(:id).last
  end

  def idle?
    sample_run.nil? && remainder_run.nil?
  end

  def skipped_sample?
    remainder_run&.all? || false
  end

  def sample_rows
    @sample_rows ||= begin
      works = sample_run&.started_at ? collection.works.where(id: sample_set&.work_ids || []).reorder(:title).to_a : []
      drafts = sample_run.ai_work_metadata.where(work_id: works.map(&:id)).index_by(&:work_id) if sample_run
      page_counts = Page.where(work_id: works.map(&:id)).group(:work_id).count
      needing = pages_needing_transcription.where(work_id: works.map(&:id)).group(:work_id).count
      works.map do |work|
        SampleRow.new(work: work, draft: drafts&.[](work.id), pages_count: page_counts[work.id].to_i,
                      needs_transcription: needing[work.id].to_i.positive?)
      end
    end
  end

  def reviewed_count
    sample_rows.count { |row| row.status == 'reviewed' }
  end

  def ready_count
    sample_rows.count { |row| row.status == 'ready' }
  end

  def failed_sample_drafts
    sample_rows.map(&:draft).compact.select(&:status_error?)
  end

  # Works outside the sample not yet drafted by a remainder or skip-the-sample run
  def remaining_works_count
    return @remaining_works_count if defined?(@remaining_works_count)

    @remaining_works_count =
      if sample_set || remainder_run
        AiWorkMetadata::StartRun.remaining_work_ids(collection).size
      else
        small_collection? ? 0 : works_count - sample_size
      end
  end

  # The rest of the collection can be drafted once the sample has been drafted (reviewed or not),
  # or after the sample was skipped, whenever there are works left and nothing is waiting or running.
  def can_draft_remaining?
    remaining_works_count.positive? && waiting_run.nil? && !remainder_running? &&
      (sample_run&.started_at.present? || skipped_sample?)
  end

  def remainder_counts
    @remainder_counts ||= remainder_run&.counts || {}
  end

  def remainder_running?
    remainder_run&.running? || false
  end

  def metadata_running?
    waiting_run.present? || remainder_running? || sample_rows.any? { |row| %w[queued drafting].include?(row.status) && row.draft }
  end

  # The page refreshes itself while anything is running
  def running?
    transcription_running? || metadata_running?
  end

  private

  def collection_pages
    Page.joins(:work).where(works: { collection_id: collection.id }).reorder(nil)
  end

  def latest_ai_transcriptions
    latest_per_page = AiTranscription.where(page_id: collection_pages.select(:id)).select('MAX(id) AS id').group(:page_id)
    AiTranscription.joins("INNER JOIN (#{latest_per_page.to_sql}) latest ON latest.id = ai_transcriptions.id")
  end

  # Pages with no human transcription and no finished AI transcription; drafting transcribes these first
  def pages_needing_transcription
    finished = AiTranscription.status_finished.where(page_id: collection_pages.select(:id)).select(:page_id)
    collection_pages.where(status: 'new').where.not(id: finished)
  end
end
