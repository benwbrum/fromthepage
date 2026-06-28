# == Schema Information
#
# Table name: ai_transcriptions
#
#  id                 :bigint           not null, primary key
#  metadata           :text(4294967295)
#  model              :string(255)      not null
#  prompt             :text(4294967295)
#  reasoning          :text(4294967295)
#  source_text        :text(4294967295)
#  status             :string(255)      default("new"), not null
#  transcription_json :text(4294967295)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  page_id            :integer          not null
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
  DEFAULT_MODEL = 'gemini-3.1-pro-preview'
  ALTO_MODEL = 'Transkribus+OpenAI'
  MAX_FAILED_ERRORS = 100
  FE_COLOR_STATUSES = {
    finished: '#6C2',
    in_progress: '#F0E68C',
    failed: '#CC4444',
    not_started: '#FFFFFF'
  }

  before_save :replace_nbsp

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

  def supports_reasoning?
    model != ALTO_MODEL
  end

  def supports_prompt?
    model != ALTO_MODEL
  end

  def engine
    self.class.engine_for_model(model)
  end

  def self.engine_for_model(model)
    model.to_s.start_with?('claude') ? 'claude' : 'gemini'
  end

  def error_message
    return if metadata.blank? || !metadata.is_a?(Hash)

    metadata['error_message']
  end

  def provider_error_details
    return {} if metadata.blank? || !metadata.is_a?(Hash)

    metadata['provider_error_details'].presence || legacy_provider_error_details
  end

  def provider_citation_sources
    provider_error_details['citation_sources'].presence || []
  end

  def display_error_message
    message = error_message.presence || 'Error details not provided'
    message.sub(/\nResponse:\s*\{.*\}\s*\z/m, '')
  end

  def short_error_message
    message = display_error_message
    message.truncate(220)
  end

  def text_for_comparison
    return source_text unless collection&.field_based && transcription_json.present?
    field_values_for_comparison(transcription_json)
  end

  # we want to replace the non-breaking space html entities Gemini 3 insists on returning with regular spaces
  def replace_nbsp
    self.source_text = source_text.gsub('&nbsp;', ' ') if source_text.present?
  end

  private

  def legacy_provider_error_details
    response = legacy_provider_response
    return {} if response.blank?

    candidate = response.dig('candidates', 0) || {}

    {
      'finish_reason' => candidate['finishReason'],
      'finish_message' => candidate['finishMessage'],
      'citation_sources' => candidate.dig('citationMetadata', 'citationSources') || [],
      'model_version' => response['modelVersion'],
      'response_id' => response['responseId'],
      'usage_metadata' => response['usageMetadata'],
      'raw_response' => response
    }.compact
  end

  def legacy_provider_response
    response_text = error_message.to_s.match(/\nResponse:\s*(\{.*\})\s*\z/m)&.[](1)
    return if response_text.blank?

    JSON.parse(response_text.gsub('=>', ':'))
  rescue JSON::ParserError
    nil
  end

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
