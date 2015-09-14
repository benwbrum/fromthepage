class DocumentUpload < ActiveRecord::Base
  belongs_to :user
  belongs_to :collection

  attr_accessible :file, :collection_id

  validates :collection_id, :file, :presence => true

  mount_uploader :file, DocumentUploader

end