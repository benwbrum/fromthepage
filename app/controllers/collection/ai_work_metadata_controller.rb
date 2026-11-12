class Collection::AiWorkMetadataController < CollectionController
  before_action :authorized?
  before_action :require_ai_work_metadata_feature, except: :show

  def show
    @ai_work_metadata = AiWorkMetadata.joins(:work).where(works: { collection_id: @collection.id }).find(params[:id])
    @work = @ai_work_metadata.work
  end

  # Skip the sample: draft every work without examples
  def create
    start_run(:all, t('collection.ai_work_metadata.create.success'))
  end

  # Step 1: draft the sample set for review
  def sample
    start_run(:sample, t('collection.ai_work_metadata.sample.success'))
  end

  # Step 2: draft the works outside the sample, using the reviewed sample works as examples
  def remainder
    start_run(:remainder, t('collection.ai_work_metadata.remainder.success'))
  end

  def retry
    drafts = AiWorkMetadata.where(ai_work_metadata_run_id: @collection.ai_work_metadata_runs.select(:id))
    @result = AiWorkMetadata::RetryFailed.new(collection: @collection, user: current_user, drafts: drafts).call
    @notice = t('collection.ai_work_metadata.retry.success')
    render_settings
  end

  private

  def start_run(kind, notice)
    @result = AiWorkMetadata::StartRun.new(collection: @collection, user: current_user, kind: kind).call
    @notice = notice
    render_settings
  end

  def render_settings
    @status = AiSettingsStatus.new(@collection)
    render :update, formats: :turbo_stream
  end

  def require_ai_work_metadata_feature
    head :not_found unless helpers.ai_work_metadata_available?(@collection)
  end
end
