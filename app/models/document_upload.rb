class DocumentUpload < ActiveRecord::Base
  belongs_to :user
  belongs_to :collection

  attr_accessible :file, :collection_id

  validates :collection, :file, :presence => true

  mount_uploader :file, DocumentUploader

end