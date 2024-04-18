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
    @uploaded_filename_available = @collection.works.where.not(uploaded_filename: nil).exists?
  end

  def create
    @bulk_export = BulkExport.new(bulk_export_params)
    if @collection.is_a? DocumentSet
      @bulk_export.document_set = @collection
      @bulk_export.collection = @collection.collection    
    else
      @bulk_export.collection = @collection
    end
    @bulk_export.work = @work if params[:work_id]
    @bulk_export.user = current_user
    @bulk_export.status = BulkExport::Status::NEW
    @bulk_export.report_arguments = bulk_export_params[:report_arguments].to_h

    if @bulk_export.save!
      @bulk_export.submit_export_process

      flash[:info] = t('.export_running_message', email: (current_user.email))
    end
    redirect_to dashboard_exports_path
  end

  def create_for_work
    # i18n-tasks isn't smart enough to follow the method call here so we need to do this to get tests to pass
    throwaway = t('.export_running_message', email: (current_user.email))
    create_for_work_actual
    redirect_to dashboard_exports_path
  end


  def create_for_work_ajax
    create_for_work_actual
    ajax_redirect_to dashboard_exports_path
  end

  def create_for_owner
    @bulk_export = BulkExport.new(bulk_export_params)
    @bulk_export.user = current_user
    @bulk_export.status = BulkExport::Status::NEW
    if bulk_export_params[:report_arguments]
      @bulk_export.report_arguments = bulk_export_params[:report_arguments].to_h
    end

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
        :plaintext_verbatim_zero_index_page,
        :tei_work, 
        :html_page, 
        :html_work, 
        :subject_csv_collection, 
        :subject_details_csv_collection,
        :table_csv_work, 
        :table_csv_collection,
        :work_metadata_csv,
        :facing_edition_work,
        :text_docx_work,
        :text_pdf_work,
        :text_only_pdf_work,
        :organization,
        :use_uploaded_filename,
        :static,
        :owner_mailing_list,
        :owner_detailed_activity,
        :collection_activity,
        :collection_contributors,
        :preserve_linebreaks,
        :work_id,
        :include_metadata, 
        :include_contributors,
        :notes_csv,
        :admin_searches,
        :report_arguments => [
          :start_date, 
          :end_date, 
          :preserve_linebreaks, 
          :include_metadata, 
          :include_contributors])
  end


private
  def create_for_work_actual
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
    if bulk_export_params[:report_arguments]
      @bulk_export.report_arguments = bulk_export_params[:report_arguments].to_h
    end

    if @bulk_export.save
      @bulk_export.submit_export_process

      flash[:info] = t('.export_running_message', email: (current_user.email))
    end
  end

end
