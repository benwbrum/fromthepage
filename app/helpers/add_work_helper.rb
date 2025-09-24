module AddWorkHelper
  include ErrorHelper

  def new_work
    @document_upload = DocumentUpload.new
    @document_upload.collection=@collection
    @universe_collections = ScCollection.universe
    @sc_collections = ScCollection.all
  end

  # Owner Dashboard - upload document
  def upload
    @document_upload = DocumentUpload.new
  end

  def new_upload
    @document_upload = DocumentUpload.new(document_upload_params)
    @document_upload.user = current_user

    if @document_upload.save
      if SMTP_ENABLED
        begin
          flash[:info] = t('document_uploaded', email: @document_upload.user.email, scope: [ :dashboard, :new_upload ])
        rescue StandardError => e
          log_smtp_error(e, current_user)
          flash[:info] = t('reload_this_page', scope: [ :dashboard, :new_upload ])
        end
      else
        flash[:info] = t('reload_this_page', scope: [ :dashboard, :new_upload ])
      end
      @document_upload.submit_process
      upload_host = Rails.application.config.upload_host
      if upload_host.present?
        host = request.host.gsub(/^#{upload_host}\./, '')
      else
        host = request.host
      end

      ajax_redirect_to controller: 'collection', action: 'show', collection_id: @document_upload.collection.id, host: host
    else
      render action: 'upload'
    end
  end

  def empty_work
    @work = Work.new
  end

  def create_work
    @work = Work.new
    @work.title = params[:work][:title]
    @work.collection_id = params[:work][:collection_id]
    @work.description = params[:work][:description]
    @work.owner = current_user
    @collections = current_user.all_owner_collections

    if @work.save
      flash[:notice] = t('work_created', scope: [ :dashboard, :create_work ])
      record_deed
      ajax_redirect_to(work_pages_tab_path(work_id: @work.id, anchor: 'create-page'))
    else
      render action: 'empty_work'
    end
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
    params.require(:document_upload).permit(:document_upload, :file, :collection_id, :ocr, :preserve_titles)
  end

  def work_params
    params.require(:work).permit(:title, :description, :collection_id)
  end
end
