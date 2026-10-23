class DocumentUpload::Create < ApplicationInteractor
  attr_accessor :document_upload, :attachment

  def initialize(document_upload_params:, user:)
    @document_upload_params = document_upload_params
    @user                   = user

    super
  end

  def perform
    @attachment = ActiveStorage::Blob.find_signed(@document_upload_params.delete(:attachment))

    @document_upload = DocumentUpload.new(@document_upload_params.except(:collection_id))

    handle_collection_id_assignment

    @document_upload.user = @user
    @document_upload.attachment = @attachment if @attachment.present?
    @document_upload.upload_file_size = @attachment.byte_size if @attachment.present?
    @document_upload.save!

    # TODO: We will move this to async job soon
    @document_upload.submit_process
  end

  private

  def handle_collection_id_assignment
    @collection = Collection::Lib::SetFriendlyFind.perform(id: @document_upload_params[:collection_id])

    if @collection.is_a?(DocumentSet)
      @document_set = @collection
      @collection = @document_set.collection
    end

    @document_upload.collection_id = @collection&.id
    @document_upload.document_set_id = @document_set&.id
  end
end
