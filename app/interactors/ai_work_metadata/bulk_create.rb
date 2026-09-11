class AiWorkMetadata::BulkCreate < ApplicationInteractor
  BATCH_SIZE = 1_000
  include AiWorkMetadata::Lib::Common

  def initialize(collection:, user:, scope: nil, model: nil)
    @collection = collection
    @user = user
    @scope = scope
    @model = model

    super
  end

  def perform
    check_user_permission

    raise ArgumentError, 'Collection has no metadata fields configured' unless @collection.metadata_fields.exists?

    @sanitized_model = sanitize_model

    ai_work_metadata_records = []

    works.find_each do |work|
      @work = work
      sanitized_prompt = build_prompt
      existing = latest_ai_work_metadata_for_model_engine(work)

      if existing.nil?
        ai_work_metadata_records << AiWorkMetadata.new(
          work_id: work.id,
          model: @sanitized_model,
          prompt: sanitized_prompt,
          status: :processing
        )
      elsif existing.status_new? || existing.status_error?
        existing.status = :processing
        existing.model = @sanitized_model
        existing.prompt = sanitized_prompt
        ai_work_metadata_records << existing
      end
    end

    AiWorkMetadata.import! ai_work_metadata_records, on_duplicate_key_update: [:status, :model, :prompt], batch_size: BATCH_SIZE
  end

  private

  def works
    return @works if defined?(@works)

    @works = @collection.works.includes(:ai_work_metadata)

    return @works if @scope.nil?

    work_ids = @scope[:work_ids] || []

    @works = @works.where(id: work_ids)

    @works
  end

  def latest_ai_work_metadata_for_model_engine(work)
    engine = AiWorkMetadata.engine_for_model(@sanitized_model)

    work.ai_work_metadata
        .sort_by(&:created_at)
        .reverse
        .detect { |ai_work_metadata| ai_work_metadata.engine == engine }
  end
end
