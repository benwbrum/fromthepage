class TableCell < ActiveRecord::Base
  belongs_to :work
  belongs_to :page
  belongs_to :section
  belongs_to :transcription_field
  
  attr_accessible :header, :row, :content

end
