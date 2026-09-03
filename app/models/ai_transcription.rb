# == Schema Information
#
# Table name: ai_transcriptions
#
#  id                             :bigint           not null, primary key
#  metadata                       :text(4294967295)
#  model                          :string(255)      not null
#  prompt                         :text(4294967295)
#  reasoning                      :text(4294967295)
#  source_text                    :text(4294967295)
#  status                         :string(255)      default("new"), not null
#  text_cer                       :decimal(10, )
#  text_cer_distance              :decimal(10, )
#  text_cer_length                :decimal(10, )
#  text_wer                       :decimal(10, )
#  text_wer_distance              :decimal(10, )
#  text_wer_length                :decimal(10, )
#  transcription_json             :text(4294967295)
#  verbatim_cer                   :decimal(10, )
#  verbatim_cer_distance          :decimal(10, )
#  verbatim_cer_length            :decimal(10, )
#  verbatim_non_stopword_accuracy :decimal(10, )
#  verbatim_wer                   :decimal(10, )
#  verbatim_wer_distance          :decimal(10, )
#  verbatim_wer_length            :decimal(10, )
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  page_id                        :integer          not null
#
# Indexes
#
#  idx_ai_transcriptions_dashboard                   (created_at,model,status)
#  index_ai_transcriptions_on_page_id                (page_id)
#  index_ai_transcriptions_on_page_id_and_id         (page_id,id)
#  index_ai_transcriptions_on_status                 (status)
#  index_ai_transcriptions_on_status_and_updated_at  (status,updated_at)
#
# Foreign Keys
#
#  fk_rails_...  (page_id => pages.id) ON DELETE => cascade
#
class AiTranscription < ApplicationRecord
  DEFAULT_MODEL = 'gemini-3.7-flash'
  ALTO_MODEL = 'Transkribus+OpenAI'
  MAX_FAILED_ERRORS = 100
  FE_COLOR_STATUSES = {
    finished: '#6C2',
    in_progress: '#F0E68C',
    failed: '#CC4444',
    not_started: '#FFFFFF'
  }

  before_save :normalize_source_text

  belongs_to :page
  has_one :work, through: :page
  has_one :collection, through: :work

  scope :alto, -> { where(model: ALTO_MODEL) }
  scope :not_alto, -> { where.not(model: ALTO_MODEL) }

  # TODO: We need to upgrade our DB version to utilize native json column field.
  # Right now we are technically using long-text field and serializing to JSON
  if (col = columns_hash['metadata']) &&
    !col.sql_type_metadata.sql_type.match?(/\bjson\b/i)
    serialize :metadata, coder: JSON
  end

  if (col = columns_hash['transcription_json']) &&
    !col.sql_type_metadata.sql_type.match?(/\bjson\b/i)
    serialize :transcription_json, coder: JSON
  end

  validates :model, presence: true

  enum :status, {
    new: 'new',
    processing: 'processing',
    finished: 'finished',
    error: 'error'
  }, prefix: :status

  def recalculate_stats?
    text_cer.nil? || text_wer.nil? || verbatim_cer.nil? || verbatim_wer.nil?
  end

  def supports_reasoning?
    model != ALTO_MODEL
  end

  def supports_prompt?
    model != ALTO_MODEL
  end

  def engine
    self.class.engine_for_model(model)
  end

  def normalize_model!
    update!(model: DEFAULT_MODEL) if model == 'gemini-3-pro-preview'
  end

  def self.engine_for_model(model)
    model.to_s.start_with?('claude') ? 'claude' : 'gemini'
  end

  def error_message
    return if metadata.blank? || !metadata.is_a?(Hash)

    AiTranscription::Lib::ErrorMessageSanitizer.sanitize(metadata['error_message'])
  end

  def provider_error_details
    return {} if metadata.blank? || !metadata.is_a?(Hash)

    metadata['provider_error_details'].presence || {}
  end

  def provider_citation_sources
    provider_error_details['citation_sources'].presence || []
  end

  def short_error_message
    message = error_message.presence || 'Error details not provided'
    message.truncate(220)
  end

  def text_for_comparison
    return source_text unless collection&.field_based && transcription_json.present?
    field_values_for_comparison(transcription_json)
  end

  # we want to replace HTML line break tags and non-breaking space entities with plain text equivalents
  def normalize_source_text
    return if source_text.blank?

    self.source_text = source_text
      .gsub(/<br\s*\/?>/i, "\n")
      .gsub('&nbsp;', ' ')
  end

  private

  def field_values_for_comparison(json)
    fields = collection.transcription_fields
                       .includes(:spreadsheet_columns)
                       .order(:line_number, :position)
    values = []
    fields.each do |field|
      next if %w[description instruction].include?(field.input_type)
      value = json[field.id.to_s]
      next if value.blank?
      if field.input_type == 'spreadsheet' && value.is_a?(Array)
        cols = field.spreadsheet_columns
        value.each do |row|
          row_text = cols.map { |c| row[c.id.to_s].to_s }.reject(&:blank?).join(' ')
          values << row_text if row_text.present?
        end
      else
        values << value.to_s
      end
    end
    values.join(' ')
  end
end
