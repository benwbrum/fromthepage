class SpreadsheetColumn < ApplicationRecord
  belongs_to :transcription_field
  acts_as_list :scope => :transcription_field

  validates :options, presence: true, if: Proc.new {|field| field.input_type == 'select'}, on: [:create, :update]

  INPUTS = ["text", "numeric", "select", "checkbox"]

end
