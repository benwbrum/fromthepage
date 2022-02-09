class QualitySampling < ApplicationRecord
  belongs_to :user
  belongs_to :collection
  validates_presence_of :percent
  before_create :calculate_field
  before_create :calculate_times

  def possible_field
    # TODO scope to sample date range
    self.collection.pages.where(status: Page::STATUS_NEEDS_REVIEW)
  end


  def calculate_field
    ids = self.possible_field.reorder('pages.id').pluck(:id)
    self.field=ids.shuffle
  end

  def calculate_times
    self.start_time = Time.now
    previous_sampling = self.collection.quality_samplings.last
    if previous_sampling
      self.previous_start = previous_sampling.start_time
    end
  end

  def total_field_size
    field.size
  end

  def needs_review_pages
    Page.where(status: Page::STATUS_NEEDS_REVIEW).where(id: field)
  end

  def next_unsampled_page
    candidate_ids = needs_review_pages.pluck(:id)
    next_unsampled_page_id = field.detect do |id|
      candidate_ids.include? id # TODO add check for current editing
    end
    Page.find(next_unsampled_page_id)
  end

  def index_within_sample(page)
    self.field.index(page.id)
  end

  def sample_page_count
    total_field_size * percent / 100
  end


  class PageSampling
    attr_accessor :reviewed_page_count, :total_page_count, :approval_delta_sum, :corrected_page_count
    def mean_approval_delta
      approval_delta_sum.to_f / reviewed_page_count.to_f
    end

    def initialize
      @reviewed_page_count = 0
      @total_page_count = 0
      @approval_delta_sum = 0.0
      @corrected_page_count = 0
    end
  end

  def sampling_objects
    work_hash = {}
    user_hash = {}
    Page.where(id:field).each do |page|
      work_sampling = work_hash[page.work_id] ||= PageSampling.new
      user_sampling = user_hash[page.last_transcriber.id] ||= PageSampling.new

      work_sampling.total_page_count += 1
      user_sampling.total_page_count += 1

      if page.approval_delta # unreviewed pages will have no delta
        work_sampling.approval_delta_sum += page.approval_delta
        user_sampling.approval_delta_sum += page.approval_delta

        if page.approval_delta > 0
          work_sampling.corrected_page_count += 1
          user_sampling.corrected_page_count += 1
        end
      end

      if Page::COMPLETED_STATUSES.include? page.status
        work_sampling.reviewed_page_count += 1
        user_sampling.reviewed_page_count += 1
      end

    end

    [work_hash, user_hash]
  end

  def pages_sampled_for(user)
    reviewed_pages = Page.where(status: Page::COMPLETED_STATUSES).where(id: field)
    reviewed_pages.select{|page| page.last_transcriber == user}.count
  end

  def mean_approval_delta_for(user)
    reviewed_pages = Page.where(status: Page::COMPLETED_STATUSES).where(id: field)
    user_pages = reviewed_pages.select{|page| page.last_transcriber == user}
    approval_deltas = user_pages.map { |page| page.approval_delta}
    approval_deltas.sum / approval_deltas.count
  end

  def pages_corrected_for(user)
    reviewed_pages = Page.where(status: Page::COMPLETED_STATUSES).where(id: field)
    user_pages = reviewed_pages.select{|page| page.last_transcriber == user}
    approval_deltas = user_pages.map { |page| page.approval_delta}
    approval_deltas.select{|delta| delta > 0.0}.count
  end

  def pages_in_field_for(user)
    reviewed_pages = Page.where(id: field)
    reviewed_pages.select{|page| page.last_transcriber == user}.count
  end

  def sampled_transcribers
    reviewed_pages = Page.where(status: Page::COMPLETED_STATUSES).where(id: field)

    transcribers = reviewed_pages.map{|page| page.last_transcriber}.uniq

    transcribers
  end

  def sampled?
    pages_already_sampled = total_field_size - needs_review_pages.count
    pages_already_sampled > sample_page_count
  end

  def field
    if self[:field].blank?
      []
    else
      JSON.parse(self[:field])
    end
  end

  def field=(array)
    self[:field]=array.to_json
  end
end
