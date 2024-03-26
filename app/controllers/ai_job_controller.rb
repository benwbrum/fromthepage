class AiJobController < ApplicationController


  # todo move these to a separate ai job controller
  def configure_ai_job_for_work
    @ai_job = AiJob.new
    @ai_job.work = @work
    @ai_job.collection = @collection
    @ai_job.user = current_user
  end


  def run_ai_job_for_work
    binding.pry


  end

private
  # permit params for ai job
  def ai_job_params
    params.require(:ai_job).permit(:job_type, :engine, :parameters)
  end

  # permit params for work
  def work_params
    params.require(:work).permit(:title, :description, :collection_id, :featured_page, :transcription_conventions, :transcription_con
  
end
