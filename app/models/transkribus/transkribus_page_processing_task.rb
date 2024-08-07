# == Schema Information
#
# Table name: page_processing_tasks
#
#  id                     :integer          not null, primary key
#  position               :integer
#  status                 :string(255)
#  type                   :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  page_processing_job_id :integer          not null
#
# Indexes
#
#  index_page_processing_tasks_on_page_processing_job_id  (page_processing_job_id)
#
# Foreign Keys
#
#  fk_rails_...  (page_processing_job_id => page_processing_jobs.id)
#
module Transkribus
  module Response
    INSUFFICIENT_CREDITS = 429
    STILL_WAITING = 'waiting'
    ERRORED = 'error'
    READY = 'ready'
  end

  # a page processing task may have more than one external API request
  # it is responsible for re-starting jobs when necessary
  
  class TranskribusPageProcessingTask < PageProcessingTask

    # Your code here
    def process_page
      # if the status is queued, launch the processing job
      if self.status == Status::QUEUED
        self.status == Status::RUNNING
        self.save
        launch_processing_job
      elsif self.status == Status::RUNNING || self.status == Status::FAILED
        # no-op
        return
      elsif self.status == Status::WAITING
        # check the job
        # status needs to be specific to this task
        status = check_status
        if status == Response::INSUFFICIENT_CREDITS
          # this account needs more Transkribus credits
          self.status == Status::FAILED
          self.save
          return
        elsif status == Response::STILL_WAITING
          self.status = Status::WAITING
          self.save
        elsif status == Response::ERRORED
          self.status = Status::RETRY
          self.save
        elsif status == Response::READY
          fetch_alto
          self.status == Status::COMPLETED
          self.save
        end
      end



      def launch_processing_job

      end

      def check_status
      end

      def fetch_alto
      end

    end

  end
end
