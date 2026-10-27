namespace :fromthepage do
  desc 'Cleans document upload original files older than 7 days'
  task clean_document_uploads: :environment do
    DocumentUpload.where(created_at: ..(7.days.ago)).find_each do |document_upload|
      if document_upload.file.present?
        document_upload.file.remove!
      end

      document_upload.attachment.purge if document_upload.attachment.present?
    end

    ActiveStorage::Blob.unattached.where(created_at: ..1.day.ago).find_each(batch_size: 10_000) do |blob|
      blob.purge
    end
  end
end
