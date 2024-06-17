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


  # params are serialized as json so we need accessors that let us work with ruby hashes
  def params
    if self[:params].blank?
      {}
    else
      JSON.parse(self[:params])
    end
  end

  def params=(hash)
    self[:params]=hash.to_json
  end

  module Engine
    TRANSKRIBUS = 'transkribus'
  end
  
end
