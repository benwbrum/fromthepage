class AiJobsController < ApplicationController
  before_action :set_ai_job, only: [:show, :edit, :update, :destroy]

  # GET /ai_jobs
  def index
    @ai_jobs = AiJob.all.paginate(:page => params[:page], :per_page => PAGES_PER_SCREEN)
  end

  # GET /ai_jobs/1
  def show
  end

  # GET /ai_jobs/new
  def new
    @ai_job = AiJob.new
  end

  # GET /ai_jobs/1/edit
  def edit
  end

  # POST /ai_jobs
  def create
    @ai_job = AiJob.new(ai_job_params)
    @ai_job.user = current_user
    @ai_job.collection = Collection.find(5)  # TODO -- change this once we are out of the admin screen
    @ai_job.status = ExternalApiRequest::Status::QUEUED

    if @ai_job.save!
      redirect_to @ai_job, notice: 'Ai job was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /ai_jobs/1
  def update
    if @ai_job.update(ai_job_params)
      redirect_to @ai_job, notice: 'Ai job was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /ai_jobs/1
  def destroy
    @ai_job.destroy
    redirect_to ai_jobs_url, notice: 'Ai job was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ai_job
      @ai_job = AiJob.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ai_job_params
      params.require(:ai_job).permit(:job_type, :engine, :parameters, :status, :page_id, :work_id, :collection_id, :user_id)
    end
end
