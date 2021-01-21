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
    @bulk_export.collection = @collection
  end

  def create
    @bulk_export = BulkExport.new(bulk_export_params)
    @bulk_export.collection = @collection
    @bulk_export.user = current_user
    @bulk_export.status = BulkExport::Status::NEW

    if @bulk_export.save
      @bulk_export.submit_export_process

      flash[:info] = "Export running.  Email will be sent to #{current_user.email} on completion."
      redirect_to collection_export_path(@collection.owner, @collection)
    else
      render :new
    end
  end

  def download
    if @bulk_export.status == BulkExport::Status::FINISHED
      # read and spew the file
      send_file(@bulk_export.zip_file_name, 
        filename: "fromthepage_export.zip", 
        :content_type => "application/zip")
    else
      flash[:info] = "This export download has been cleaned.  Please start a new one."
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
      params.require(:bulk_export).permit(:user_id, :collection_id, :zip_file, :status, :plaintext_verbatim, :plaintext_emended, :plaintext_searchable, :tei, :html, :subject_csv, :field_csv, :page_level, :work_level, :collection_level)
    end
end
