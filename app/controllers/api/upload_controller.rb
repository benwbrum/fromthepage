class Api::UploadController < Api::ApiController
  
  def create
    @document_upload = DocumentUpload.new(params[:document_upload])
    @document_upload.user = current_user

    if @document_upload.save
      
      alert = GamificationHelper.uploadWorkEvent(current_user.email)
      
      if SMTP_ENABLED
        begin
          # SystemMailer.new_upload(@document_upload).deliver!
          # "Document has been uploaded and will be processed shortly. We'll email you at #{@document_upload.user.email} when ready."
        rescue StandardError => e
          log_smtp_error(e, current_user)
        end
      end
      # ajax_redirect_to controller: 'collection', action: 'show', collection_id: @document_upload.collection.id
      @document_upload.submit_process
      render_serialized ResponseWS.simple_ok('api.upload.create.success',alert)
    else
      # render action: 'upload'
      render_serialized ResponseWS.simple_error('api.upload.create.error')
    end
  end

end
