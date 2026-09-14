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
  MAX_FAILED_ERRORS = 100
  FE_COLOR_STATUSES = {
    finished: '#6C2',
    in_progress: '#F0E68C',
    failed: '#CC4444',
    not_started: '#FFFFFF'
  }.freeze

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
    model_name = model.to_s

    return 'claude' if model_name.start_with?('claude')
    return 'openai' if model_name.start_with?('gpt', 'o1', 'o3', 'o4', 'chatgpt')

    'gemini'
  end

  CollectionStats = Struct.new(
    :works_count, :ai_work_metadata_count, :queued_count, :finished_count,
    :failed_count, :not_started_count, :failed_records, :failed_hidden_count,
    :total_token_count,
    keyword_init: true
  )

  def self.stats_for_collection(collection)
    works = collection.works.reorder(nil)

    latest_per_work = where(work_id: works.select(:id))
      .select('MAX(id) AS id')
      .group(:work_id)

    latest_ai_work_metadata = joins("INNER JOIN (#{latest_per_work.to_sql}) latest ON latest.id = ai_work_metadata.id")

    ai_work_metadata_count, new_count, processing_count, finished_count, error_count =
      latest_ai_work_metadata.pick(
        Arel.sql('COUNT(*)'),
        Arel.sql("SUM(CASE WHEN ai_work_metadata.status = 'new' THEN 1 ELSE 0 END)"),
        Arel.sql("SUM(CASE WHEN ai_work_metadata.status = 'processing' THEN 1 ELSE 0 END)"),
        Arel.sql("SUM(CASE WHEN ai_work_metadata.status = 'finished' THEN 1 ELSE 0 END)"),
        Arel.sql("SUM(CASE WHEN ai_work_metadata.status = 'error' THEN 1 ELSE 0 END)")
      )

    works_count = works.count
    ai_work_metadata_count = ai_work_metadata_count.to_i
    failed_count = error_count.to_i

    failed_records = latest_ai_work_metadata
      .where(status: :error)
      .includes(:work)
      .order(updated_at: :desc)
      .limit(MAX_FAILED_ERRORS)

    total_token_count = latest_ai_work_metadata
      .where(status: :finished)
      .sum("COALESCE(JSON_EXTRACT(metadata, '$.total_token_count'), 0)")

    CollectionStats.new(
      works_count: works_count,
      ai_work_metadata_count: ai_work_metadata_count,
      queued_count: new_count.to_i + processing_count.to_i,
      finished_count: finished_count.to_i,
      failed_count: failed_count,
      not_started_count: works_count - ai_work_metadata_count,
      failed_records: failed_records,
      failed_hidden_count: [0, failed_count - failed_records.size].max,
      total_token_count: total_token_count
    )
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
