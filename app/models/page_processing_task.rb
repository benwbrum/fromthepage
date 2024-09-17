# == Schema Information
#
# Table name: page_processing_tasks
#
#  id                     :integer          not null, primary key
#  details                :text(65535)
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
class PageProcessingTask < ApplicationRecord
  belongs_to :page_processing_job
  acts_as_list scope: :page_processing_job
  has_one :page, through: :page_processing_job
  has_one :ai_job, through: :page_processing_job
  has_many :external_api_requests
  serialize :details, Hash


  module Status
    QUEUED = 'queued' # everything should start as queued
    RUNNING = 'running'
    WAITING = 'waiting'
    FETCHING = 'fetching'
    COMPLETED = 'completed'
    FAILED = 'failed'
    RETRY = 'retry'
  end


  def process_page
  end



end
