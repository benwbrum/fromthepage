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

  mount_uploader :file, DocumentUploader
  has_one_attached :attachment

  enum status: {
    new: 'new',
    queued: 'queued',
    processing: 'processing',
    finished: 'finished',
    error: 'error'
  }, _prefix: :status

  def log_file
    File.join(upload_dir, 'process.log')
  end

  def name
    File.basename(file.to_s)
  end

  private

  def upload_dir
    File.dirname(file.path)
  end
end
