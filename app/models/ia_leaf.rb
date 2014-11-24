class IaLeaf < ActiveRecord::Base
  self.table_name = "ia_leaves"
  belongs_to :ia_work
  belongs_to :page
  
  def thumb_url
    "http://www.archive.org/download/#{ia_work.book_id}/page/leaf#{leaf_number}_thumb.jpg"
  end
end
