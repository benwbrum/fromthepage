class BulkExportController < ApplicationController
  before_action :set_bulk_export, only: [:show, :edit, :download]

  PAGES_PER_SCREEN = 20

  def index
    @bulk_exports = BulkExport.all.order('id DESC').paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
  end

  def show
  end

  def new
    @bulk_export = BulkExport.new
    if @collection.is_a? DocumentSet
      @bulk_export.document_set = @collection
      @bulk_export.collection = @collection.collection    
    else
      @bulk_export.collection = @collection
    end
  end

  def create
    @bulk_export = BulkExport.new(bulk_export_params)
    if @collection.is_a? DocumentSet
      @bulk_export.document_set = @collection
      @bulk_export.collection = @collection.collection    
    else
      @bulk_export.collection = @collection
    end
    @bulk_export.user = current_user
    @bulk_export.status = BulkExport::Status::NEW

    if @bulk_export.save!
      @bulk_export.submit_export_process

      flash[:info] = t('.export_running_message', email: (current_user.email))
    end
    redirect_to dashboard_exports_path
  end

  def create_for_work
    @bulk_export = BulkExport.new(bulk_export_params)
    if @collection.is_a? DocumentSet
      @bulk_export.document_set = @collection
      @bulk_export.collection = @collection.collection    
    else
      @bulk_export.collection = @collection
    end
    @bulk_export.work = @work
    @bulk_export.user = current_user
    @bulk_export.status = BulkExport::Status::NEW

    if @bulk_export.save
      @bulk_export.submit_export_process

      flash[:info] = t('.export_running_message', email: (current_user.email))
    end
    redirect_to dashboard_exports_path
  end

  def download
    if @bulk_export.status == BulkExport::Status::FINISHED
      # read and spew the file
      send_file(@bulk_export.zip_file_name, 
        filename: "fromthepage_export.zip", 
        :content_type => "application/zip")
      cookies['download_finished'] = 'true'
    else
      flash[:info] = t('.download_cleaned_message')
      redirect_to collection_export_path(@bulk_export.collection.owner, @bulk_export.collection)
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bulk_export
      @bulk_export = BulkExport.find(params[:bulk_export_id])
    end

    # Only allow a trusted parameter "white list" through.
    def bulk_export_params
      params.require(:bulk_export).permit(
        :user_id, 
        :collection_id, 
        :plaintext_verbatim_page, 
        :plaintext_verbatim_work, 
        :plaintext_emended_page, 
        :plaintext_emended_work, 
        :plaintext_searchable_page, 
        :plaintext_searchable_work, 
        :tei_work, 
        :html_page, 
        :html_work, 
        :subject_csv_collection, 
        :table_csv_work, 
        :table_csv_collection,
        :work_metadata_csv,
        :facing_edition_work,
        :text_docx_work,
        :text_pdf_work,
        :static)
    end
end
