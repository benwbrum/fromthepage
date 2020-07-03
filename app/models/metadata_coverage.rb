class MetadataCoverage < ApplicationRecord
  belongs_to :collection
  has_one :facet_config
  before_save :increment_count

  def increment_count
    self.count = self.count + 1
  end
end
