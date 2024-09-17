# == Schema Information
#
# Table name: ai_results
#
#  id                      :integer          not null, primary key
#  engine                  :string(255)
#  parameters              :string(255)
#  result                  :string(255)
#  task_type               :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  ai_job_id               :integer          not null
#  collection_id           :integer          not null
#  external_api_request_id :integer          not null
#  page_id                 :integer
#  user_id                 :integer          not null
#  work_id                 :integer
#
# Indexes
#
#  index_ai_results_on_ai_job_id                (ai_job_id)
#  index_ai_results_on_collection_id            (collection_id)
#  index_ai_results_on_external_api_request_id  (external_api_request_id)
#  index_ai_results_on_page_id                  (page_id)
#  index_ai_results_on_user_id                  (user_id)
#  index_ai_results_on_work_id                  (work_id)
#
# Foreign Keys
#
#  fk_rails_...  (ai_job_id => ai_jobs.id)
#  fk_rails_...  (collection_id => collections.id)
#  fk_rails_...  (external_api_request_id => external_api_requests.id)
#  fk_rails_...  (page_id => pages.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (work_id => works.id)
#
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
