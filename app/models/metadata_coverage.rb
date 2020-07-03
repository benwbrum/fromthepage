class MetadataCoverage < ApplicationRecord
  belongs_to :collection
  has_one :facet_config
  after_create :initial_count
  validates :key, uniqueness: { case_sensitive: true }

  def initial_count
    if self.count.nil?
      self.count = 1
      self.save
    end
  end
end
