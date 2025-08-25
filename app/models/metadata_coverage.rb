# == Schema Information
#
# Table name: metadata_coverages
#
#  id            :integer          not null, primary key
#  count         :integer          default(0)
#  key           :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :integer
#
class MetadataCoverage < ApplicationRecord
  belongs_to :collection
  has_one :facet_config, dependent: :destroy
  validates :key, uniqueness: { case_sensitive: true, scope: :collection_id }
  validates :key, presence: true
end
