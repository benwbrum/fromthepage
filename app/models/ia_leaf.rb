# == Schema Information
#
# Table name: ia_leaves
#
#  id          :integer          not null, primary key
#  leaf_number :integer
#  ocr_text    :text(65535)
#  page_h      :integer
#  page_number :string(255)
#  page_type   :string(255)
#  page_w      :integer
#  created_at  :datetime
#  updated_at  :datetime
#  ia_work_id  :integer
#  page_id     :integer
#
# Indexes
#
#  index_ia_leaves_on_page_id  (page_id)
#
class IaLeaf < ApplicationRecord
  self.table_name = 'ia_leaves'
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

  def iiif_image_info_url
    "https://iiif.archive.org/iiif/#{ia_work.book_id}$#{leaf_number}/info.json"
  end
end
