# == Schema Information
#
# Table name: external_api_requests
#
#  id            :integer          not null, primary key
#  engine        :string(255)
#  params        :text(65535)
#  status        :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  ai_job_id     :integer
#  collection_id :integer          not null
#  page_id       :integer
#  user_id       :integer          not null
#  work_id       :integer
#
# Indexes
#
#  index_external_api_requests_on_ai_job_id      (ai_job_id)
#  index_external_api_requests_on_collection_id  (collection_id)
#  index_external_api_requests_on_page_id        (page_id)
#  index_external_api_requests_on_user_id        (user_id)
#  index_external_api_requests_on_work_id        (work_id)
#
# Foreign Keys
#
#  fk_rails_...  (ai_job_id => ai_jobs.id)
#  fk_rails_...  (collection_id => collections.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (work_id => works.id)
#
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
