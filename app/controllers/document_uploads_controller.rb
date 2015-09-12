class DocumentUploadsController < ApplicationController

  before_action :set_document_upload, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @document_uploads = DocumentUpload.all
    respond_with(@document_uploads)
  end

  def show
    respond_with(@document_upload)
  end

  def new
    @document_upload = DocumentUpload.new
    respond_with(@document_upload)
  end

  def create
    @document_upload = DocumentUpload.new(document_upload_params)
    @document_upload.user = current_user

    if @document_upload.save
      flash[:notice] = "Document has been uploaded and will be processed shortly. We'll email you at #{@document_upload.user.email} when ready."
      SystemMailer.new_upload(@document_upload).deliver!
      redirect_to controller: 'collection', action: 'show', collection_id: @document_upload.collection.id
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    @document_upload.update(document_upload_params)
    respond_with(@document_upload)
  end

  def destroy
    @document_upload.destroy
    respond_with(@document_upload)
  end

private
  def set_document_upload
    @document_upload = DocumentUpload.find(params[:id])
  end

  def document_upload_params
    params.require(:document_upload).permit(:user_id, :collection_id, :file)
  end

end