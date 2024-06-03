# frozen_string_literal: true

class TranscriptionField < ApplicationRecord
  belongs_to :collection, optional: true

  acts_as_list scope: :collection

  has_many :table_cells
  has_many :spreadsheet_columns, -> { order 'position' }, dependent: :destroy

  validates :options, presence: true, if: Proc.new { |field| field.input_type == 'select' }, on: [:create, :update]
  validates :percentage, numericality: { allow_nil: true, greater_than: 0, less_than_or_equal_to: 100 }
  validates :page_number, numericality: { allow_nil: true, greater_than: 0, less_than_or_equal_to: 1000 }
  validates :label, format: { without: /[\[\]]/, message: "cannot contain '[' or ']'" }

  module FieldType
    TRANSCRIPTION = 'transcription'
    METADATA = 'metadata'
  end

  TRANSCRIPTION_INPUTS = ['text', 'select', 'date', 'textarea',
                          'description', 'instruction', 'spreadsheet', 'alt text'].freeze
  METADATA_INPUTS = ['text', 'select', 'date', 'multiselect', 'textarea', 'instruction', 'alt text'].freeze
end
