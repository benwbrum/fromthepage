# == Schema Information
#
# Table name: ai_jobs
#
#  id            :integer          not null, primary key
#  engine        :string(255)
#  job_type      :string(255)
#  parameters    :text(65535)
#  status        :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :integer          not null
#  page_id       :integer
#  user_id       :integer          not null
#  work_id       :integer
#
# Indexes
#
#  index_ai_jobs_on_collection_id  (collection_id)
#  index_ai_jobs_on_page_id        (page_id)
#  index_ai_jobs_on_user_id        (user_id)
#  index_ai_jobs_on_work_id        (work_id)
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#  fk_rails_...  (page_id => pages.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (work_id => works.id)
#
class AiJob < ApplicationRecord
  belongs_to :page, optional: true
  belongs_to :work, optional: true
  belongs_to :collection
  belongs_to :user
  has_many :ai_results
  has_many :external_api_requests
  before_create :set_task_specific_params
  before_create :set_defaults
  after_create :run_rake_task


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

  # TODO re-write in light of 
  module Status
    QUEUED = 'queued'
    RUNNING = 'running'
    WAITING = 'waiting'
    COMPLETED = 'completed'
    FAILED = 'failed'

    def self.running
      [RUNNING, WAITING]
    end
  end

  def set_defaults
    self.status=Status::QUEUED
  end

  def set_task_specific_params
    if self.job_type == JobType::HTR
      self.engine = Engine::TRANSKRIBUS
      self.parameters = {
        'model_id' => PageProcessor::Model::TEXT_TITAN_I,
      }
    elsif self.job_type == JobType::AI_TEXT
      self.engine = Engine::OPEN_AI
      self.parameters = {
        'replacement'=> 'word'
      }
    end
  end

  # TODO make this make sense
  def run_rake_task
    if self.job_type == JobType::HTR
      Rake::Task['transkribus_processing:process_page'].invoke(self.page_id)
    elsif self.job_type == JobType::AI_TEXT
      Rake::Task['open_ai:process_page'].invoke(self.page_id)
    end
  end

  # main loop -- to be run in background by a rake task; other tasks will be run inline
  def process


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

  
private
  def all_requests_finished?

  end

  def any_requests_errored?

  end


  def needs_ai_text?

  end



end
