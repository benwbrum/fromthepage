class AiJob < ApplicationRecord
  belongs_to :work
  belongs_to :collection
  belongs_to :user
  has_many :external_api_requests




  # run rake tasks depending on job type
  def submit_background_process

  end

  module JobType
    HTR = 'htr'
  end

  module Status
    QUEUED = 'queued'
    RUNNING = 'running'
    WAITING = 'waiting'
    COMPLETED = 'completed'
    FAILED = 'failed'

    def self.running
      [QUEUED, RUNNING, WAITING]
    end
  end

  module Engine
    TRANSKRIBUS = 'transkribus'
  end


end
