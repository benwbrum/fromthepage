module AddWorkHelper
  include ErrorHelper

  def new_work
    @document_upload = DocumentUpload.new
    @document_upload.collection=@collection
    @universe_collections = ScCollection.universe
    @sc_collections = ScCollection.all
  end

  protected

  def record_deed
    deed = Deed.new
    deed.work = @work
    deed.deed_type = DeedType::WORK_ADDED
    deed.collection = @work.collection
    deed.user = current_user
    deed.save!
  end

  def document_upload_params
    params.require(:document_upload).permit(
      :document_upload,
      :file,
      :attachment,
      :collection_id,
      :ocr,
      :preserve_titles,
      :generate_ai_draft
    )
  end

  def work_params
    params.require(:work).permit(:title, :description, :collection_id)
  end
end
