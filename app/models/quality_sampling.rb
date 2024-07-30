# == Schema Information
#
# Table name: quality_samplings
#
#  id            :integer          not null, primary key
#  sample_set    :text(16777215)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :integer          not null
#  user_id       :integer          not null
#
# Indexes
#
#  index_quality_samplings_on_collection_id  (collection_id)
#  index_quality_samplings_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#  fk_rails_...  (user_id => users.id)
#
class QualitySampling < ApplicationRecord
  belongs_to :user
  belongs_to :collection
  before_create :calculate_set

  MINIMUM_SAMPLE_SIZE = 5

  # attr_writer :additional_pages

  # module SamplingType
  #   EACH_USER='each_user'
  #   EACH_WORK='each_work'
  #   TOGETHER='together'
  #   PERMUTATIONS='permutations'

  #   ALL=[EACH_WORK,EACH_USER,TOGETHER,PERMUTATIONS]
  # end

  def current_field
    self.collection.pages.where(status: :needs_review)
  end

  def calculate_set
    working_set = self.sample_set || []

    all_triples = self.collection.pages.pluck(:work_id, :last_editor_user_id, 'pages.id')
    all_triples_by_work = all_triples.group_by { |triple| triple[0] } # work_id
    all_triples_by_user = all_triples.group_by { |triple| triple[1] } # user_id

    # look for unique works/users in the current field (pages needing review)
    review_triples = current_field.pluck(:work_id, :last_editor_user_id, 'pages.id')
    review_triples_by_work = review_triples.group_by { |triple| triple[0] } # work_id
    review_triples_by_user = review_triples.select{ |triple| !triple[1].nil? }.group_by{ |triple| triple[1] }# user_id

    # for each user, add the relevant pages to the sample
    review_triples_by_user.sort.each do |user_id, review_triples_for_user|
      # how many of this user's pages are in the set?
      user_page_ids = all_triples_by_user[user_id].map{|user_triple| user_triple[2]}
      user_pages_in_set = working_set & user_page_ids
      if user_pages_in_set.size < MINIMUM_SAMPLE_SIZE
        # append target pages
        user_review_page_ids = review_triples_for_user.map{|review_triple| review_triple[2]}
        user_review_page_ids_not_in_set = user_review_page_ids - working_set
        working_set += user_review_page_ids_not_in_set.sample(MINIMUM_SAMPLE_SIZE - user_pages_in_set.size)
      end
    end

    # do the same for works
    review_triples_by_work.sort.each do |work_id, review_triples_for_work|
      # how many of this work's pages are in the set?
      work_page_ids = all_triples_by_work[work_id].map{|work_triple| work_triple[2]}
      work_pages_in_set = working_set & work_page_ids
      if work_pages_in_set.size < MINIMUM_SAMPLE_SIZE
        # append target pages
        work_review_page_ids = review_triples_for_work.map{|review_triple| review_triple[2]}
        work_review_page_ids_not_in_set = work_review_page_ids - working_set
        working_set += work_review_page_ids_not_in_set.sample(MINIMUM_SAMPLE_SIZE - work_pages_in_set.size)
      end
    end

    self.sample_set = working_set
  end




  def total_field_size
    current_field.size
  end

  def needs_review_pages
    Page.where(status: :needs_review).where(id: sample_set)
  end

  def next_unsampled_page
    candidate_ids = needs_review_pages.pluck(:id)
    next_unsampled_page_id = sample_set.detect do |id|
      candidate_ids.include? id # TODO add check for current editing
    end
    Page.where(id: next_unsampled_page_id).first
  end

  def index_within_sample(page)
    self.sample_set.index(page.id)
  end

  def sample_page_count
    self.sample_set.size
  end

  def sampled?
    !needs_review_pages.present?
  end

  def sample_set
    if self[:sample_set].blank?
      []
    else
      JSON.parse(self[:sample_set])
    end
  end

  def sample_set=(array)
    self[:sample_set]=array.to_json
  end

  def max_approval_delta
    Page.where(id:sample_set).where.not(approval_delta: nil).maximum(:approval_delta)
  end

  def sampling_objects
    work_hash = {}
    user_hash = {}

    ## this is wrong!  we should display the stats for the whole collection, not just the set
    # for users:
    ## total_page_count should be all pages the user has worked on (pr just been last editor on)
    ## approval_delta should be the total for the pages the user has been last_editor on.
    ##    (note that we may need to calcuate the average completely differently than we do now)
    ## corrected_page_count should be the pages that had an approval count > 0
    # replace reviewed page count with pages needing review


    # for works:
    ## total page count should be the total pages in the work
    ## approval delta should be the total/average for the pages in the work that have one and
    ##    are in a completed state (since reviewed pages can be opened again)
    ## corrected_page_count should be pages in completed state with approval delta > 0
    #  replace reviewed_page_count with pages needing review.
    ##
    Page.where(id:sample_set).each do |page|
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


end
