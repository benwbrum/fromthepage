class DocumentUpload < ActiveRecord::Base
  attr_accessible :file, :collection_id
  belongs_to :user
  belongs_to :collection
  
  mount_uploader :file, DocumentUploader
end
