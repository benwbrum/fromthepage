class TableCell < ActiveRecord::Base
  belongs_to :work
  belongs_to :page
  belongs_to :section
  belongs_to :transcription_field
  
  attr_accessible :header, :row, :content

  scope :page_order, -> { order 'section_id, row, header' }
  scope :work_order , -> { order 'page_id, row, header' }

end
