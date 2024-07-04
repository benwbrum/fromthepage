namespace :fromthepage do
  desc 'Cleans document upload original files older than 7 days'
  task clean_document_uploads: :environment do
    DocumentUpload.where(created_at: ..(Time.now - 7.days)).each do |document_upload|
      document_upload.file.remove! if document_upload.file.present?
    end
  end
end
