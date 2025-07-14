class MoveDocumentUploadAttachmentsToActiveStorage < ActiveRecord::Migration[6.1]
  BATCH_SIZE = 1_000

  def up
    DocumentUpload.find_each(batch_size: BATCH_SIZE) do |document_upload|
      next if document_upload.attachment.attached?

      next unless document_upload.file.present?

      file_path = document_upload.file.path
      filename = File.basename(file_path)

      document_upload.attachment.attach(
        io: File.open(file_path),
        filename: filename,
        content_type: document_upload.file.content_type
      )

      document_upload.save!
    end
  end

  def down
    DocumentUpload.find_each(batch_size: BATCH_SIZE) do |document_upload|
      document_upload.attachment.purge if document_upload.attachment.attached?
    end
  end
end
