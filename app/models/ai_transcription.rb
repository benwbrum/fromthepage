# == Schema Information
#
# Table name: ai_transcriptions
#
#  id          :bigint           not null, primary key
#  metadata    :text(4294967295)
#  model       :string(255)      not null
#  prompt      :text(65535)
#  reasoning   :text(65535)
#  source_text :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  page_id     :integer          not null
#
# Indexes
#
#  index_ai_transcriptions_on_page_id  (page_id)
#
# Foreign Keys
#
#  fk_rails_...  (page_id => pages.id) ON DELETE => cascade
#
class AiTranscription < ApplicationRecord
  ALTO_MODEL = 'Transkribus+OpenAI'
  belongs_to :page

  scope :alto, -> { where(model: ALTO_MODEL) }
  scope :not_alto, -> { where.not(model: ALTO_MODEL) }

  # TODO: We need to upgrade our DB version to utilize native json column field.
  # Right now we are technically using long-text field and serializing to JSON
  if (col = columns_hash['metadata']) &&
    !col.sql_type_metadata.sql_type.match?(/\bjson\b/i)
    serialize :metadata, coder: JSON
  end
end
