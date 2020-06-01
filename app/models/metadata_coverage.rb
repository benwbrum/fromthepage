class MetadataCoverage < ApplicationRecord
  belongs_to :collection
  has_one :facet_config
end
