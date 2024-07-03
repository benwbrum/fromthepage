# == Schema Information
#
# Table name: document_uploads
#
#  id              :integer          not null, primary key
#  file            :string(255)
#  ocr             :boolean          default(FALSE)
#  preserve_titles :boolean          default(FALSE)
#  status          :string(255)      default("new")
#  created_at      :datetime
#  updated_at      :datetime
#  collection_id   :integer
#  user_id         :integer
#
# Indexes
#
#  index_document_uploads_on_collection_id  (collection_id)
#  index_document_uploads_on_user_id        (user_id)
#
class DocumentUpload < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :collection, optional: true

  validates :collection_id, :file, :presence => true

  mount_uploader :file, DocumentUploader

  module Status
    NEW = 'new'
    QUEUED = 'queued'
    PROCESSING = 'processing'
    FINISHED = 'finished'
    ERROR = 'error'
  end

  def submit_process
    self.status = Status::QUEUED
    self.save
    rake_call = "#{RAKE} fromthepage:process_document_upload[#{self.id}]  --trace >> #{log_file} 2>&1 &"

    # Nice-up the rake call if settings are present
    rake_call = "nice -n #{NICE_RAKE_LEVEL} " << rake_call if NICE_RAKE_ENABLED

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
