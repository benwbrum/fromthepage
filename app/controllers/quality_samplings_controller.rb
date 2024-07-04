class QualitySamplingsController < ApplicationController

  before_action :set_quality_sampling, only: [:show, :edit, :update, :destroy, :review]
  before_action :authorized?

  # GET /quality_samplings
  def index
    # do we have a sampling?
    return if @collection.quality_sampling.blank?

    redirect_to collection_quality_sampling_path(@collection.owner, @collection, @collection.quality_sampling)
  end

  # GET /quality_samplings/1
  def show
    old_set_size = @quality_sampling.sample_set.size
    @quality_sampling.calculate_set
    new_set_size = @quality_sampling.sample_set.size
    if new_set_size > old_set_size
      @quality_sampling.save!
      flash[:notice] = t('.sample_set_has_increased', increase: (new_set_size - old_set_size))
    end

    @work_samplings, @user_samplings = @quality_sampling.sampling_objects
    # TODO: sometimes work_samplings returns bad data -- why?
    @works = Work.where(id: @work_samplings.keys).sort { |a, b| a.id <=> b.id }
    @users = User.where(id: @user_samplings.keys).sort { |a, b| a.id <=> b.id }
    @max_approval_delta = @quality_sampling.max_approval_delta
  end

  def review
    redirect_to collection_sampling_review_page_path(@collection.owner, @collection, @quality_sampling,
      @quality_sampling.next_unsampled_page, flow: 'quality-sampling')
  end

  def initialize_sample
    @quality_sampling = QualitySampling.new
    @quality_sampling.collection = @collection
    @quality_sampling.user = current_user

    if @quality_sampling.save
      # redirect_to collection_quality_sampling_path(@collection.owner, @collection, @quality_sampling), notice: 'Quality sampling was successfully created.'
      redirect_to collection_sampling_review_flow_path(@collection.owner, @collection, @quality_sampling)
    else
      render :index
    end
  end

  # PATCH/PUT /quality_samplings/1
  def update
    if @quality_sampling.update(quality_sampling_params)
      redirect_to @quality_sampling, notice: t('.quality_sampling_updated')
    else
      render :edit
    end
  end

  # DELETE /quality_samplings/1
  def destroy
    @quality_sampling.destroy
    redirect_to quality_samplings_url, notice: t('.quality_sampling_destroyed')
  end

  private

  def authorized?
    return false if user_signed_in? && current_user.can_review?(@collection)

    redirect_to new_user_session_path
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_quality_sampling
    @quality_sampling = QualitySampling.find(params[:id])
  end

  # Only allow a trusted parameter "white list" through.
  def quality_sampling_params
    params.require(:quality_sampling).permit(:sample_type, :start_time, :previous_start, :user_id, :collection_id, :field,
      :additional_pages)
  end

end
