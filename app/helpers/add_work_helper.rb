module AddWorkHelper
  include ErrorHelper

  def new_work
    @document_upload = DocumentUpload.new
    @document_upload.collection=@collection
    @omeka_items = OmekaItem.all
    @omeka_sites = current_user.omeka_sites
    @universe_collections = ScCollection.universe
    @sc_collections = ScCollection.all
  end

  # Owner Dashboard - omeka import
  def omeka
    @omeka_items = OmekaItem.all
    @omeka_sites = current_user.omeka_sites
  end

  # Owner Dashboard - upload document
  def upload
    @document_upload = DocumentUpload.new
  end

  def new_upload
    @document_upload = DocumentUpload.new(params[:document_upload])
    @document_upload.user = current_user

    if @document_upload.save
      if SMTP_ENABLED
        begin
          SystemMailer.new_upload(@document_upload).deliver!
          flash[:notice] = "Document has been uploaded and will be processed shortly. We'll email you at #{@document_upload.user.email} when ready."
        rescue StandardError => e
          log_smtp_error(e, current_user)
          flash[:notice] = "Document has been uploaded and will be processed shortly. Reload this page in a few minutes to see it."
        end
      else
        flash[:notice] = "Document has been uploaded and will be processed shortly. Reload this page in a few minutes to see it."
      end
      @document_upload.submit_process
      ajax_redirect_to controller: 'collection', action: 'show', collection_id: @document_upload.collection.id
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
      flash[:notice] = 'Work created successfully'
      record_deed
      ajax_redirect_to({ :controller => 'work', :action => 'pages_tab', :work_id => @work.id, :anchor => 'create-page' })
    else
      render action: 'empty_work'
    end
  end

  protected
  def record_deed
    deed = Deed.new
    deed.work = @work
    deed.deed_type = Deed::WORK_ADDED
    deed.collection = @work.collection
    deed.user = current_user
    deed.save!
  end

end
