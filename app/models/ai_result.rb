class AiResult < ApplicationRecord
  belongs_to :page
  belongs_to :work
  belongs_to :collection
  belongs_to :user
  belongs_to :ai_job
  belongs_to :external_api_request


  # tasks may include running HTR, running a correction script and/or running creating ai_text
  module TaskType
    HTR = 'htr'
    AI_TEXT = 'ai_text'
  end

  module Engine
    TRANSKRIBUS = 'transkribus'
    OPEN_AI = 'open_ai'
  end

  # parameters should be stored as a jsonified hash
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
