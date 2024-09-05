# == Schema Information
#
# Table name: page_processing_jobs
#
#  id         :integer          not null, primary key
#  status     :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  ai_job_id  :integer          not null
#  page_id    :integer          not null
#
# Indexes
#
#  index_page_processing_jobs_on_ai_job_id  (ai_job_id)
#  index_page_processing_jobs_on_page_id    (page_id)
#
# Foreign Keys
#
#  fk_rails_...  (ai_job_id => ai_jobs.id)
#  fk_rails_...  (page_id => pages.id)
#
class PageProcessingJob < ApplicationRecord
  belongs_to :ai_job
  belongs_to :page
  has_many :page_processing_tasks
  after_create :create_tasks

  module Status
    QUEUED = 'queued' # everything should start as queued
    RUNNING = 'running'
    # Do we need this?
    WAITING = 'waiting' # waiting on external API requests to finish
    COMPLETED = 'completed'
    FAILED = 'failed'

    def self.all
      [QUEUED, IN_PROGRESS, COMPLETED, FAILED]
    end
  end

  # when the page processing job is created, read the ai job task configuration and create tasks
  def create_tasks
    if ai_job.job_type == AiJob::JobType::HTR || ai_job.job_type == AiJob::JobType::HTR_AND_AI_TEXT
      self.page_processing_tasks << Transkribus::TranskribusPageProcessingTask.new(status: PageProcessingTask::Status::QUEUED)
    end

    if ai_job.job_type == AiJob::JobType::AI_TEXT || ai_job.job_type == AiJob::JobType::HTR_AND_AI_TEXT
      self.page_processing_tasks << OpenAi::AiTextPageProcessingTask.new(status: PageProcessingTask::Status::QUEUED)
    end
  end

  def run_tasks
    # assume that this may be called multiple times, as when waiting for an external API response
    # these may also be run in parallel

    # if we are in a failed or completed state, bail out
    if self.status == Status::COMPLETED || self.status == Status::FAILED
      return
    end

    # if we are in a running status, a different process is running this job, so bail out
    if self.status == Status::RUNNING
      logger.info("Another process is running job #{self.id}")
      return
    end

    # we are in a queued or waiting state, so start processing tasks
    self.status = Status::RUNNING
    self.save
    
    # reload us from the database to refresh status
    self.page_processing_tasks.each do |task|
      # reload from the db 
      task.reload
      if task.status == PageProcessingTask::Status::FAILED
        # update status and bail out
        self.status = Status::FAILED
        self.save
        return
      end

      if task.status == PageProcessingTask::Status::COMPLETED
        next # move to the next task
      end

      # if the task is in the RETRY status, duplicate it and run the new task
      if task.status == PageProcessingTask::Status::RETRY
        # duplicate the task attributes
        new_task = task.dup
        # set the status to QUEUED
        new_task.status = PageProcessingTask::Status::QUEUED
        new_task.save
        # run this task instead
        task = new_task
      end

  
      # now the task is in a non-completed statue
      # actually run the next step in this task
      task.process_page
      # the task's status should have been updated
      # if the task has completed, the loop should continue naturally
      if task.status == PageProcessingTask::Status::FAILED
        # update status and bail out
        self.status = Status::FAILED
        self.save
        return
      elsif task.status == PageProcessingTask::Status::WAITING
        # update status and bail out
        self.status = PageProcessingTask::Status::WAITING
        self.save
        return
      end
      # continue to remaining tasks
    end
  end
end
