class TableCell < ActiveRecord::Base
  belongs_to :work
  belongs_to :page
  belongs_to :section
  
  attr_accessible :header, :row, :content

end
