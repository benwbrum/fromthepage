class TableCell < ApplicationRecord
  belongs_to :work, optional: true
  belongs_to :page, optional: true
  belongs_to :section, optional: true
  belongs_to :transcription_field, optional: true
  
  attr_accessible :header, :row, :content

  scope :page_order, -> { order 'section_id, row, header' }
  scope :work_order , -> { order 'page_id, row, header' }

end
