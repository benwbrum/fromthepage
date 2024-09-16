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
  has_many :external_api_requests # TODO: this should be through the page processing jobs
  has_many :page_processing_jobs, dependent: :destroy
  before_create :set_task_specific_params
  before_create :set_defaults
  # after_create :run_rake_task

  serialize :parameters, Hash

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


  # states for the whole API job
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
        'model_id' => Transkribus::Model::TEXT_TITAN_I,
      }
    elsif self.job_type == JobType::AI_TEXT
      self.engine = Engine::OPEN_AI
      self.parameters = {
        'replacement'=> 'word'
      }
    end
  end

 
  # # TODO change to a hash serialization like we do with work.metadata already and get rid of this code
  # # parameters should be stored as a jsonified hash (but consider using job-type specific accessors)
  # def parameters
  #   if self[:parameters].nil?
  #     return {}
  #   end
  #   JSON.parse(self[:parameters])
  # end

  # task_class_name is the name of a subclass of PageProcessingTask.
  # it will include any module names, e.g. 'OpenAi::AiTextPageProcessingTask'
  def task_parameters(task_class_name)
    self.parameters[task_class_name]
  end


  # def parameters=(value)
  #   self[:parameters] = value.to_json
  # end



  # fininite state machine transitions
  def start
    self.status = Status::QUEUED
    self.save
    # launch background task
  end

  def submit_page_processes
    self.status = Status::RUNNING
    self.save

    # loop through all the pages for this job and get them started
    pages = []
    if self.page # this job is page specific
      pages = [self.page]
    elsif self.work # this job is work specific
      pages = self.work.pages
    elsif self.collection # this job is collection specific
      pages = self.collection.pages
      # TODO: handle page sets
    end

    # now create a page process for each page
    # (these will be harvested and run by a background job)
    pages.each do |page|
      PageProcessingJob.create(ai_job: self, page: page, status: PageProcessingJob::Status::QUEUED)
    end

    self.status=Status::WAITING
    self.save
  end


  # this will be a call-back by the child processes
  def update_status
    # check the status of all child page processing jobs and update our status accordingly
    if self.page_processing_jobs.where.not(status: PageProcessingJob::Status::COMPLETED).exists?
      if self.page_processing_jobs.where(status: PageProcessingJob::Status::FAILED).exists?
        self.status = Status::FAILED
      else
        self.status = Status::RUNNING
      end
    else
      self.status = Status::COMPLETED
    end
    self.save 
  end





end
