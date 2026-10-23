# == Schema Information
#
# Table name: cdm_export_settings
#
#  id                    :bigint           not null, primary key
#  ai_provenance_field   :string(255)
#  fulltext_field        :string(255)
#  include_ai_provenance :boolean          default(FALSE), not null
#  prepend_ai_warning    :boolean          default(FALSE), not null
#  transcript_source     :string(255)      default("human_only"), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  collection_id         :integer          not null
#
# Indexes
#
#  index_cdm_export_settings_on_collection_id  (collection_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#
class CdmExportSetting < ApplicationRecord
  belongs_to :collection

  HUMAN_ONLY    = 'human_only'
  HUMAN_AND_AI  = 'human_and_ai'

  validates :transcript_source, inclusion: { in: [HUMAN_ONLY, HUMAN_AND_AI] }
end
