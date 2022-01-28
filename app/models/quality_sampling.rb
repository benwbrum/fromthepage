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
    self.previous_start = previous_sampling.start_time
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


  def sampled?
    pages_to_sample = total_field_size * percent / 100
    pages_already_sampled = total_field_size - needs_review_pages.count

    pages_already_sampled > pages_to_sample
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
