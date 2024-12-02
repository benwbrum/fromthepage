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
  self.table_name = "ia_leaves"
  belongs_to :ia_work, optional: true
  belongs_to :page, optional: true

  CACHE_DIRECTORY_ROOT = File.join(Rails.root, 'public', 'images', 'ia_cache')

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

  def refresh_cache
    unless File.exist?(cache_file_path)
      unless Dir.exist?(cache_dir_path)
        Dir.mkdir(cache_dir_path)
      end
      # import the image
      fetch_and_save_image(facsimile_url, cache_file_path)
    end
  end

  def fetch_and_save_image(url, local_path)
    URI.open(url) do |image|
      File.open(local_path, 'wb') do |file|
        file.write(image.read)
      end
    end
  end

  def cache_file_path
    File.join(cache_dir_path, "leaf#{leaf_number}")
  end

  def cache_dir_path
    File.join(CACHE_DIRECTORY_ROOT, ia_work.book_id)
  end

end
