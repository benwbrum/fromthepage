class AiTranscription::BatchGenerate < ApplicationInteractor
  attr_accessor :ai_batch_generations

  POLL_INTERVAL = 10.minutes
  BATCH_SIZE = 100

  def initialize(collection:, user:, scope: nil)
    @collection = collection
    @user = user
    @scope = scope
    @ai_batch_generations = []

    super
  end

  def perform
    pages.in_batches(of: BATCH_SIZE).each do |batch|
      handle_batch(batch)
    end

    @ai_batch_generations.each do |ai_batch_generation|
      enqueue_polling(ai_batch_generation)
    end
  end

  private

  def pages
    return @pages if defined?(@pages)

    @pages = @collection.pages

    if @scope.present?
      @pages = @pages.where(work_id: @scope[:work_ids] || [])
    end

    active_batch_ids = @collection.ai_batch_generations
                                  .where(status: [:new, :processing])
                                  .select(:id)

    @pages = @pages.where.not(
      id: AiBatchGenerationPage.where(
        ai_batch_generation_id: active_batch_ids
      ).select(:page_id)
    )

    @pages
  end

  def handle_batch(batch)
    # NOTE: We only support scoping to 1 work at a time
    # if we launch through work/ai settings
    ai_batch_generation = AiBatchGeneration.create!(
      collection: @collection,
      work_id: @scope&.dig(:work_ids)&.first,
      status: :processing
    )

    # TODO: Ideally we do not call an interactor within an interactor,
    # and instead write a common lib handler for overlapping logic.
    # We will refactor this soon.
    result = AiTranscription::BulkCreate.new(
      collection: @collection,
      user: @user,
      scope: { page_ids: batch.pluck(:id) }
    ).call

    raise result.full_errors unless result.success?

    records = batch.reload.includes(:ai_transcription).map do |page|
      [
        ai_batch_generation.id,
        page.id,
        page.ai_transcription.id
      ]
    end

    AiBatchGenerationPage.import!(
      [:ai_batch_generation_id, :page_id, :ai_transcription_id],
      records
    )

    AiTranscription::Lib::Gemini::BatchTranscribeHandler.new(
      ai_batch_generation: ai_batch_generation.reload
    ).perform

    @ai_batch_generations << ai_batch_generation if ai_batch_generation.present?
  rescue StandardError => e
    if ai_batch_generation.present?
      ai_batch_generation.update!(status: :error)

      @ai_batch_generations << ai_batch_generation
    end

    raise e
  end

  def enqueue_polling(batch)
    AiTranscription::BatchPollJob.set(wait: POLL_INTERVAL).perform_later(
      user_id: @user.id,
      ai_batch_generation_id: batch.id
    )
  end
end
