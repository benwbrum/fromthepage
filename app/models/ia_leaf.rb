class IaLeaf < ActiveRecord::Base
  self.table_name = "ia_leaves"
  belongs_to :ia_work, optional: true
  belongs_to :page, optional: true

  def thumb_url
    "https://www.archive.org/download/#{ia_work.book_id}/page/leaf#{leaf_number}_thumb.jpg"
  end

  def facsimile_url
    "https://www.archive.org/download/#{ia_work.book_id}/page/leaf#{leaf_number}.jpg"
  end

  def small_url
    "https://www.archive.org/download/#{ia_work.book_id}/page/leaf#{leaf_number}_small.jpg"
  end

end
