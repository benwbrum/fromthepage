class DocumentUpload::Create < ApplicationInteractor
  attr_accessor :document_upload, :attachment

  def initialize(document_upload_params:, user:)
    @document_upload_params = document_upload_params
    @user                   = user
    @attachment             = nil

    super
  end

  def perform
    @attachment = ActiveStorage::Blob.find_signed(@document_upload_params.delete(:attachment))

    @document_upload = DocumentUpload.new(@document_upload_params)
    @document_upload.user = @user
    @document_upload.status = :queued
    @document_upload.attachment = @attachment if @attachment.present?

    @document_upload.save!

    DocumentUpload::ProcessJob.perform_later(
      document_upload_id: @document_upload.id
    )
  end
end
