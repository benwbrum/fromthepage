class DocumentUpload < ActiveRecord::Base
  belongs_to :user
  belongs_to :collection

  attr_accessible :file, :collection_id, :status

  validates :collection_id, :file, :presence => true

  mount_uploader :file, DocumentUploader
  
  module Status 
    NEW = 'new'
    QUEUED = 'queued'
    PROCESSING = 'processing'
    FINISHED = 'finished'
  end
  
  def submit_process
    self.status = Status::QUEUED
    self.save
    rake_call = "#{RAKE} fromthepage:process_document_upload[#{self.id}]  --trace 2>&1 >> #{log_file} &"
    logger.info rake_call
    system(rake_call)
  end

  def log_file
    File.join(upload_dir, "process.log")
  end

  def name
    File.basename(self.file.to_s)
  end

private
  def upload_dir
    if self.file && self.file.path
      File.dirname(self.file.path)
    else
      "/tmp/fromthepage_rake.log"
    end
  end
  
end