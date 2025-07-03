class DocumentUpload::Create < ApplicationInteractor
  attr_accessor :document_upload, :attachment

  def initialize(document_upload_params:, user:)
    @document_upload_params = document_upload_params
    @user                   = user
    @attachment             = nil

    super
  end

  def perform
    @document_upload = DocumentUpload.new(@document_upload_params)
    @document_upload.user = @user
    @document_upload.status = :queued

    if @document_upload.save
      DocumentUpload::ProcessJob.perform_later(
        document_upload_id: @document_upload.id
      )
    else
      @attachment = ActiveStorage::Blob.find_signed(@document_upload_params[:attachment])

      context.fail!
    end
  end
end
