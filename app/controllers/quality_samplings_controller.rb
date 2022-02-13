class QualitySamplingsController < ApplicationController
  before_action :set_quality_sampling, only: [:show, :edit, :update, :destroy]

  # GET /quality_samplings
  def index
    @quality_samplings = @collection.quality_samplings
  end

  # GET /quality_samplings/1
  def show
    @work_samplings, @user_samplings = @quality_sampling.sampling_objects
    @works = Work.find(@work_samplings.keys)
    @users = User.find(@user_samplings.keys)
    @max_approval_delta = @quality_sampling.max_approval_delta
  end

  # GET /quality_samplings/new
  def new
    @quality_sampling = QualitySampling.new
    @quality_sampling.collection = @collection
  end

  # GET /quality_samplings/1/edit
  def edit
  end

  # POST /quality_samplings
  def create
    @quality_sampling = QualitySampling.new(quality_sampling_params)
    @quality_sampling.collection = @collection
    @quality_sampling.user = current_user

    if @quality_sampling.save
      redirect_to collection_quality_samplings_path, notice: 'Quality sampling was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /quality_samplings/1
  def update
    if @quality_sampling.update(quality_sampling_params)
      redirect_to @quality_sampling, notice: 'Quality sampling was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /quality_samplings/1
  def destroy
    @quality_sampling.destroy
    redirect_to quality_samplings_url, notice: 'Quality sampling was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_quality_sampling
      @quality_sampling = QualitySampling.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def quality_sampling_params
      params.require(:quality_sampling).permit(:percent, :start_time, :previous_start, :user_id, :collection_id, :field)
    end
end
