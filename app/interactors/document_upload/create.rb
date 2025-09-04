class DocumentUpload::Create < ApplicationInteractor
  attr_accessor :document_upload, :attachment

  def initialize(document_upload_params:, user:)
    @document_upload_params = document_upload_params
    @user                   = user

    super
  end

  def perform
    @document_upload = DocumentUpload.new(@document_upload_params)
    @document_upload.user = @user
    @document_upload.save!

    # TODO: We will move this to async job soon
    @document_upload.submit_process
  end
end
