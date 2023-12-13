class ExternalApiRequest < ApplicationRecord
  belongs_to :user
  belongs_to :collection
  belongs_to :work
  belongs_to :page


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
