# == Schema Information
#
# Table name: spreadsheet_columns
#
#  id                     :integer          not null, primary key
#  input_type             :string(255)
#  label                  :string(255)
#  options                :text(65535)
#  position               :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  transcription_field_id :integer          not null
#
# Indexes
#
#  index_spreadsheet_columns_on_transcription_field_id  (transcription_field_id)
#
# Foreign Keys
#
#  fk_rails_...  (transcription_field_id => transcription_fields.id)
#
class SpreadsheetColumn < ApplicationRecord

  belongs_to :transcription_field
  acts_as_list scope: :transcription_field

  validates :options, presence: true, if: proc { |field| field.input_type == 'select' }, on: [:create, :update]

  INPUTS = ['text', 'numeric', 'select', 'checkbox', 'date']

end
