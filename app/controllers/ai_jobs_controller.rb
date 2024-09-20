class AiJobsController < ApplicationController
  before_action :set_ai_job, only: [:show, :edit, :update, :destroy]


  def new_ai_job_collection
    @ai_job = AiJob.new
    @ai_job.collection = @collection
    @ai_job.user = current_user
  end

  def run_ai_job_collection

  end

  def new_ai_job_work
    @ai_job = AiJob.new
    @ai_job.work = @work
    @ai_job.collection = @collection
    @ai_job.user = current_user
    render :new
  end

  def run_ai_job_work

  end

  def new_htr_job_page
    # consider generalizing htr jobs vs ai jobs
    @ai_job = AiJob.new
    @ai_job.page = @page
    @ai_job.work = @work
    @ai_job.collection = @collection
    @ai_job.user = current_user
    if @collection.field_based?
      @ai_job.job_type = AiJob::JobType::HTR
    else
      @ai_job.job_type = AiJob::JobType::HTR_AND_AI_TEXT
    end

    render :new, layout: false
  end

  def runhtr_job_work

  end


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
    @ai_job.collection = @collection
    @ai_job.work = @work
    @ai_job.page = @page
    if @ai_job.save
      flash[:notice]='HTR Job was successfully created.'
      if @page
        ajax_redirect_to collection_work_page_htr_jobs_path(@collection.owner, @collection, @work, @page)
        # redirect_to collection_work_page_htr_jobs_path(@collection.owner, @collection, @work, @page)
      elsif @work
        redirect_to collection_work_edit_path(@collection.owner, @collection, @work)
      else
        redirect_to collection_edit_path(@collection.owner, @collection)
      end
    else
      render :new, status: :unprocessable_entity
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
