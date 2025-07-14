class DocumentUpload::ProcessJob < ApplicationJob
  queue_as :default

  def perform(document_upload_id:)
    document_upload = DocumentUpload.find(document_upload_id)

    DocumentUpload::Process.new(document_upload: document_upload).call
  end
end
