class AiTranscription < ApplicationRecord
  DEFAULT_MODEL = 'gemini-3.1-pro-preview'
  ALTO_MODEL = 'Transkribus+OpenAI'
  TEXTRACT_ALTO_MODEL = 'Textract'
  ALTO_MODELS = [ALTO_MODEL, TEXTRACT_ALTO_MODEL].freeze
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

  scope :alto, -> { where(model: ALTO_MODELS) }
  scope :not_alto, -> { where.not(model: ALTO_MODELS) }

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
    !ALTO_MODELS.include?(model)
  end

  def supports_prompt?
    !ALTO_MODELS.include?(model)
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
