# == Schema Information
#
# Table name: ai_work_metadata
#
#  id            :bigint           not null, primary key
#  metadata      :text(4294967295)
#  metadata_json :text(4294967295)
#  model         :string(255)      not null
#  prompt        :text(4294967295)
#  reasoning     :text(4294967295)
#  status        :string(255)      default("new")
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  work_id       :integer          not null
#
# Indexes
#
#  index_ai_work_metadata_on_status   (status)
#  index_ai_work_metadata_on_work_id  (work_id)
#
# Foreign Keys
#
#  fk_rails_...  (work_id => works.id) ON DELETE => cascade
#
class AiWorkMetadata < ApplicationRecord
  self.table_name = 'ai_work_metadata'

  DEFAULT_MODEL = 'gemini-3.7-flash'

  belongs_to :work
  has_one :collection, through: :work

  # TODO: We need to upgrade our DB version to utilize native json column field.
  # Right now we are technically using long-text field and serializing to JSON
  if (col = columns_hash['metadata']) &&
    !col.sql_type_metadata.sql_type.match?(/\bjson\b/i)
    serialize :metadata, coder: JSON
  end

  if (col = columns_hash['metadata_json']) &&
    !col.sql_type_metadata.sql_type.match?(/\bjson\b/i)
    serialize :metadata_json, coder: JSON
  end

  validates :model, presence: true

  enum :status, {
    new: 'new',
    processing: 'processing',
    finished: 'finished',
    error: 'error'
  }, prefix: :status

  def engine
    self.class.engine_for_model(model)
  end

  def self.engine_for_model(model)
    model.to_s.start_with?('claude') ? 'claude' : 'gemini'
  end

  def error_message
    return if metadata.blank? || !metadata.is_a?(Hash)

    AiTranscription::Lib::ErrorMessageSanitizer.sanitize(metadata['error_message'])
  end

  def short_error_message
    message = error_message.presence || 'Error details not provided'
    message.truncate(220)
  end
end
