# == Schema Information
#
# Table name: ia_works
#
#  id             :integer          not null, primary key
#  archive_format :string(255)      default("zip")
#  collection     :string(255)
#  contributor    :string(255)
#  creator        :string(255)
#  description    :text(16777215)
#  detail_url     :string(255)
#  djvu_file      :string(255)
#  ia_path        :string(255)
#  image_count    :string(255)
#  image_format   :string(255)      default("jp2")
#  notes          :string(255)
#  scandata_file  :string(255)
#  server         :string(255)
#  sponsor        :string(255)
#  subject        :string(255)
#  title          :string(1028)
#  title_leaf     :integer
#  use_ocr        :boolean          default(FALSE)
#  zip_file       :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  book_id        :string(255)
#  user_id        :integer
#  work_id        :integer
#
# Legacy record for works imported by the old archive.org scraper, kept so those
# works still display.  New Internet Archive imports go through IIIF
# (see InternetArchiveTranslator).
class IaWork < ApplicationRecord
  DESCRIPTION_MAX_LENGTH = 16.megabytes - 1

  belongs_to :user, optional: true
  belongs_to :work, optional: true
  has_many :ia_leaves, class_name: 'IaLeaf'

  validates :description, html: true, length: { maximum: DESCRIPTION_MAX_LENGTH }
end
