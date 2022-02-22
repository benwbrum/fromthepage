class QualitySampling < ApplicationRecord
  belongs_to :user
  belongs_to :collection
  validates_presence_of :sample_type
  before_create :calculate_field
  before_create :calculate_times

  attr_writer :additional_pages

  module SamplingType
    EACH_USER='each_user'
    EACH_WORK='each_work'
    TOGETHER='together'
    PERMUTATIONS='permutations'

    ALL=[EACH_WORK,EACH_USER,TOGETHER,PERMUTATIONS]
  end

  def possible_field
    # TODO scope to sample date range
    self.collection.pages.where(status: Page::STATUS_NEEDS_REVIEW)
  end


  def calculate_field
    ids = self.possible_field.reorder('pages.id').pluck(:id)
    unique_field = calculate_unique_field
    self.pages_in_sample = unique_field.count + @additional_pages.to_i
    self.field=unique_field + (ids - unique_field).shuffle
  end

  def work_count
    self.possible_field.pluck(:work_id).uniq.count
  end

  def user_count
    self.possible_field.pluck(:last_editor_user_id).uniq.count
  end

  def together_count
    self.covered_set_together.count
  end

  def permutation_count
    self.possible_field.pluck(:work_id, :last_editor_user_id).uniq.count
  end    

  def calculate_unique_field
    if self.sample_type == SamplingType::EACH_USER
      covered_set_per_user
    elsif self.sample_type == SamplingType::EACH_WORK
      covered_set_per_work
    elsif self.sample_type == SamplingType::TOGETHER
      covered_set_together
    else
      covered_set_per_permutation
    end
  end

  def covered_set_per_permutation
    possible_field.group(:work_id, :last_editor_user_id).minimum('pages.id').values
  end

  def covered_set_per_user
    possible_field.group(:last_editor_user_id).minimum('pages.id').values
  end

  def covered_set_per_work
    possible_field.group(:work_id).minimum('pages.id').values
  end


  def covered_set_together
    # users = self.possible_field.pluck(:last_editor_user_id).uniq
    # works = self.possible_field.pluck(:work_id).uniq
    # permutations = self.possible_field.pluck(:last_editor_user_id, :work_id).uniq


    # pseudocode
    array_of_work_user_page_ids = possible_field.pluck(:last_editor_user_id, :work_id, :id)
    covered_user_ids = []
    covered_work_ids = []
    working_page_id_list = []

    count_per_user = self.possible_field.group(:last_editor_user_id).count
    count_per_work = self.possible_field.group(:work_id).count

    max_number_pages = [count_per_user.max_by{|k,v| v}[1],count_per_work.max_by{|k,v| v}[1]].max

    1.upto(max_number_pages) do |current_count|
      # binding.pry if current_count > 20
      users_at_current_count = count_per_user.select{|k,v| v==current_count}
      users_at_current_count.each do |user_id, count|
        unless covered_user_ids.include?(user_id)
          new_unique_page_by_work = 
            array_of_work_user_page_ids.select{|triple| triple[0]==user_id}.detect{|triple| !covered_work_ids.include?(triple[1])}
          if new_unique_page_by_work
            working_page_id_list << new_unique_page_by_work[2]
            covered_user_ids << user_id
            covered_work_ids << new_unique_page_by_work[1]
          else
            triple =
              array_of_work_user_page_ids.select{|triple| triple[0]==user_id}.sample(1).first
            working_page_id_list << triple[2]
            covered_user_ids << user_id
          end
        end
      end

      works_at_current_count = count_per_work.select{|k,v| v==current_count}
      works_at_current_count.each do |work_id, count|
        unless covered_work_ids.include?(work_id)
          unique_triple_by_user = 
            array_of_work_user_page_ids.select{|triple| triple[1]==work_id}.detect{|triple| !covered_user_ids.include?(triple[0])}
          if unique_triple_by_user
            working_page_id_list << unique_triple_by_user[2]
            covered_work_ids << work_id
            covered_user_ids << unique_triple_by_user[0]
          else
            triple =
              array_of_work_user_page_ids.select{|triple| triple[1]==work_id}.sample(1).first
            working_page_id_list << triple[2]
            covered_work_ids << work_id
          end
        end
      end
    end
    working_page_id_list
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
    self.pages_in_sample
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

  def max_approval_delta
    Page.where(id:field).where.not(approval_delta: nil).maximum(:approval_delta)
  end

  def sampling_objects
    work_hash = {}
    user_hash = {}
    Page.where(id:field).each do |page|
      work_sampling = work_hash[page.work_id] ||= PageSampling.new
      user_sampling = user_hash[page.last_editor_user_id] ||= PageSampling.new

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
