class MetadataCoverage < ApplicationRecord
  belongs_to :collection
  has_one :facet_config, :dependent => :destroy
  validates :key, uniqueness: { case_sensitive: true }
  validates :key, presence: true
end
