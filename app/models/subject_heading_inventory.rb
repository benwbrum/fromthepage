# The saved subject headings for a field. Only Configure Subject Headings creates one;
# validation lives separately in SubjectHeadingValidation.
class SubjectHeadingInventory < ApplicationRecord
  belongs_to :transcription_field
  has_many :subject_headings, dependent: :delete_all
  serialize :source_rows, coder: JSON

  def unique_count
    @unique_count ||= subject_headings.count
  end

  def duplicate_count
    row_count - unique_count
  end
end
