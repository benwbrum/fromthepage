# == Schema Information
#
# Table name: document_uploads
# Database name: primary
#
#  id                :integer          not null, primary key
#  file              :string(255)
#  generate_ai_draft :boolean          default(FALSE)
#  ocr               :boolean          default(FALSE)
#  preserve_titles   :boolean          default(FALSE)
#  status            :string(255)      default("new")
#  created_at        :datetime
#  updated_at        :datetime
#  collection_id     :integer
#  document_set_id   :integer
#  user_id           :integer
#
# Indexes
#
#  index_document_uploads_on_collection_id    (collection_id)
#  index_document_uploads_on_document_set_id  (document_set_id)
#  index_document_uploads_on_user_id          (user_id)
#
class DocumentUpload < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :collection, optional: true
  belongs_to :document_set, optional: true

  validates :collection_id, presence: true

  ACCEPTED_FILE_TYPES = [
    'application/pdf',
    'application/zip'
  ].freeze

  FE_ACCEPTED_FILE_TYPES = [
    'application/x-zip',
    'application/x-zip-compressed'
  ].freeze

  validates :attachment, attached: true, on: :create
  validates :attachment, content_type: ACCEPTED_FILE_TYPES, on: :create

  has_one_attached :attachment

  # TODO: We will soon deprecate DocumentUploader in favor of ActiveStorage
  mount_uploader :file, DocumentUploader

  enum :status, {
    new: 'new',
    queued: 'queued',
    processing: 'processing',
    finished: 'finished',
    error: 'error'
  }, prefix: :status

  def submit_process
    self.status = :queued
    self.save

    FileUtils.mkdir_p(upload_dir)

    rake_call = "#{RAKE} fromthepage:process_document_upload[#{self.id}]  --trace >> #{log_file} 2>&1 &"

    # Nice-up the rake call if settings are present
    rake_call = "nice -n #{NICE_RAKE_LEVEL} " << rake_call if NICE_RAKE_ENABLED
    logger.info rake_call
    system(rake_call)
  end

  def log_file
    File.join(upload_dir, 'process.log')
  end

  def name
    File.basename(self.attachment.filename.to_s)
  end

  private

  # TODO: This will be deprecated soon
  def upload_dir
    Rails.root.join('public', 'uploads', 'document_upload', 'file', self.id.to_s).to_s
  end
end
