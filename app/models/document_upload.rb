class DocumentUpload < ActiveRecord::Base
  belongs_to :user
  belongs_to :collection

  attr_accessible :file, :collection_id

  mount_uploader :file, DocumentUploader
  validate :check_file

  def check_file
    if file.blank?
      errors.add(:file, " is not defined, you should select a file to upload")
    end
  end

end