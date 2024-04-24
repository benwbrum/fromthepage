class AiJob < ApplicationRecord
  belongs_to :page, optional: true
  belongs_to :work, optional: true
  belongs_to :collection
  belongs_to :user
  has_many :ai_results
  has_many :external_api_requests


  module JobType
    HTR = 'htr'
    AI_TEXT = 'ai_text'
    HTR_AND_AI_TEXT = 'htr_and_ai_text'

    def self.all
      [HTR, AI_TEXT, HTR_AND_AI_TEXT]
    end
  end

  module Engine
    TRANSKRIBUS = 'transkribus'
    OPEN_AI = 'open_ai'

    def self.all
      [TRANSKRIBUS, OPEN_AI]
    end
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

    # parameters should be stored as a jsonified hash (but consider using job-type specific accessors)
    def parameters
      if self[:parameters].nil?
        return {}
      end
      JSON.parse(self[:parameters])
    end
  
    def parameters=(value)
      self[:parameters] = value.to_json
    end
  
end
