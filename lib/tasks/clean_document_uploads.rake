namespace :fromthepage do
  desc 'Cleans document upload original files older than 7 days'
  task clean_document_uploads: :environment do
    DocumentUpload.where(created_at: ..(Time.now - 7.days)).each do |document_upload|
      if document_upload.file.present?
        document_upload.file.remove!
      end
    end
  end
end
