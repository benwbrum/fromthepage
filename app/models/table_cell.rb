# == Schema Information
#
# Table name: table_cells
#
#  id                     :integer          not null, primary key
#  content                :text(65535)
#  header                 :string(255)
#  row                    :integer
#  created_at             :datetime
#  updated_at             :datetime
#  page_id                :integer
#  section_id             :integer
#  transcription_field_id :integer
#  work_id                :integer
#
# Indexes
#
#  index_table_cells_on_page_id                 (page_id)
#  index_table_cells_on_section_id              (section_id)
#  index_table_cells_on_transcription_field_id  (transcription_field_id)
#  index_table_cells_on_work_id                 (work_id)
#
class TableCell < ApplicationRecord

  belongs_to :work, optional: true
  belongs_to :page, optional: true
  belongs_to :section, optional: true
  belongs_to :transcription_field, optional: true

  scope :page_order, -> { order 'section_id, row, header' }
  scope :work_order, -> { order 'page_id, row, header' }

end
