# == Schema Information
#
# Table name: ai_transcriptions
#
#  id          :bigint           not null, primary key
#  metadata    :text(4294967295)
#  model       :string(255)      not null
#  prompt      :text(4294967295)
#  reasoning   :text(4294967295)
#  source_text :text(4294967295)
#  status      :string(255)      default("new"), not null
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
  DEFAULT_MODEL = 'gemini-3-pro-preview'
  ALTO_MODEL = 'Transkribus+OpenAI'
  FE_COLOR_STATUSES = {
    finished: '#6C2',
    in_progress: '#F0E68C',
    failed: '#CC4444',
    not_started: '#FFFFFF'
  }

  belongs_to :page
  before_save :replace_nbsp

  scope :alto, -> { where(model: ALTO_MODEL) }
  scope :not_alto, -> { where.not(model: ALTO_MODEL) }

  # TODO: We need to upgrade our DB version to utilize native json column field.
  # Right now we are technically using long-text field and serializing to JSON
  if (col = columns_hash['metadata']) &&
    !col.sql_type_metadata.sql_type.match?(/\bjson\b/i)
    serialize :metadata, coder: JSON
  end

  validates :model, presence: true

  enum :status, {
    new: 'new',
    processing: 'processing',
    finished: 'finished',
    error: 'error'
  }, prefix: :status

  # we want to replace the non-breaking space html entities Gemini 3 insists on returning with regular spaces
  def replace_nbsp
    self.source_text = source_text.gsub('&nbsp;', ' ') if source_text.present?
  end
end