require 'contentdm_translator'

class ExportController < ApplicationController
  require 'zip'
  include CollectionHelper, ExportHelper, ExportService

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil } #, :only => [:update, :update_profile]

  def index
    # @collection = Collection.friendly.find(params[:collection_id])
    #check if there are any translated works in the collection
    if @collection.works.where(supports_translation: true).exists?
      @header = "Translated"
    else
      @header = "Transcribed"
    end

    @works = @collection.works.includes(:work_statistic).paginate(page: params[:page], per_page: 15)

    @table_export = @collection.works.joins(:table_cells).where.not(table_cells: {work_id: nil}).distinct
  end

  def show
    xhtml = work_to_xhtml(@work)

    render :text => xhtml, :layout => false
  end

  def printable
    output_file = export_printable(@work, params[:edition], params[:format], false, true, true)    

    if params[:format] == 'pdf'
      content_type = "application/pdf"
    elsif params[:format] == 'doc'
      content_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    end

    # spew the output to the browser
    send_data(File.read(output_file), 
      filename: File.basename(output_file), 
      :content_type => content_type)
    cookies['download_finished'] = 'true'
  end

  def text
    @work = Work.includes(pages: [:notes, {page_versions: :user}]).find_by(id: params[:work_id])
    render :layout => false
  end

  def transcript
    @work = Work.includes(pages: [:notes, {page_versions: :user}]).find_by(id: params[:work_id])
    render :layout => false
  end

  def translation
    @work = Work.includes(pages: [:notes, {page_versions: :user}]).find_by(id: params[:work_id])
    render :layout => false
  end

  def tei
    tei_xml = work_to_tei(@work, current_user)

    render :text => tei_xml, :content_type => "application/xml", :layout => false
  end

  def subject_details_csv
    send_data(@collection.export_subject_details_as_csv,
              :filename => "fromthepage_subject_details_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
              :type => "application/csv")
    cookies['download_finished'] = 'true'
  end


  def subject_coocurrence_csv
    send_data(@collection.export_subject_coocurrence_as_csv,
              :filename => "fromthepage_subject_coocurrence_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
              :type => "application/csv")
    cookies['download_finished'] = 'true'
  end

  def subject_distribution_csv
    send_data(@collection.export_subject_distribution_as_csv(@article),
              :filename => "fromthepage_subject_distribution_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
              :type => "application/csv")
    cookies['download_finished'] = 'true'
  end

  def subject_index_csv
    send_data(@collection.export_subject_index_as_csv,
              :filename => "fromthepage_subject_index_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
              :type => "application/csv")
    cookies['download_finished'] = 'true'
  end

  def work_metadata_csv
    send_data(export_work_metadata_as_csv(@collection),
              :filename => "fromthepage_work_metadata_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
              :type => "application/csv")
    cookies['download_finished'] = 'true'
  end


  def table_csv
    send_data(export_tables_as_csv(@work),
              :filename => "fromthepage_tables_export_#{@work.id}_#{Time.now.utc.iso8601}.csv",
              :type => "text/csv")
    cookies['download_finished'] = 'true'
  end



  def export_all_tables
    send_data(export_tables_as_csv(@collection),
              :filename => "fromthepage_tables_export_#{@collection.id}_#{Time.now.utc.iso8601}.csv",
              :type => "application/csv")
    cookies['download_finished'] = 'true'

  end

  def page_plaintext_verbatim
    render  :layout => false, :content_type => "text/plain", :plain => @page.verbatim_transcription_plaintext
  end

  def page_plaintext_translation_verbatim
    render  :layout => false, :content_type => "text/plain", :plain => @page.verbatim_translation_plaintext
  end

  def page_plaintext_emended
    render  :layout => false, :content_type => "text/plain", :plain => @page.emended_transcription_plaintext
  end

  def page_plaintext_translation_emended
    render  :layout => false, :content_type => "text/plain", :plain => @page.emended_translation_plaintext
  end

  def page_plaintext_searchable
    render  :layout => false, :content_type => "text/plain", :plain => @page.search_text
  end

  def work_plaintext_verbatim
    render  :layout => false, :content_type => "text/plain", :plain => @work.verbatim_transcription_plaintext
  end

  def work_plaintext_translation_verbatim
    render  :layout => false, :content_type => "text/plain", :plain => @work.verbatim_translation_plaintext
  end

  def work_plaintext_emended
    render  :layout => false, :content_type => "text/plain", :plain => @work.emended_transcription_plaintext
  end

  def work_plaintext_translation_emended
    render  :layout => false, :content_type => "text/plain", :plain => @work.emended_translation_plaintext
  end

  def work_plaintext_searchable
    render  :layout => false, :content_type => "text/plain", :plain => @work.searchable_plaintext
  end


  def edit_contentdm_credentials
    # display the edit form
  end

  def update_contentdm_credentials
    # test credentials
    license_key = params[:collection][:license_key]
    contentdm_user_name = params[:contentdm_user_name]
    contentdm_password = params[:contentdm_password]
    error_message, fts_field = ContentdmTranslator.fts_field_for_collection(@collection)

    # persist license key so the user doesn't have to retype it
    if error_message.blank? || !error_message.match(/license.*invalid/)
      @collection.license_key = license_key
      @collection.save!
    end

    # redirect to or render edit screen with error
    if error_message
      flash[:error] = error_message
      render :action => :edit_contentdm_credentials, :collection_id => @collection.id
      return
    end

    # pass credentials, FTS field, and search to background job
    log_file = ContentdmTranslator.log_file(@collection)
    unless Dir.exist? File.dirname(log_file)
      FileUtils.mkdir_p(File.dirname(log_file))
    end    
    cmd = "rake fromthepage:cdm_transcript_export[#{@collection.id}] > #{log_file} 2>&1 &"
    logger.info(cmd)
    system({'contentdm_username' => contentdm_user_name, 'contentdm_password' => contentdm_password, 'contentdm_license' => license_key}, cmd)

    # display results somehow
    flash[:notice] = t('.updating_contentdm_message')
    ajax_redirect_to :action => :index, :collection_id => @collection.id
  end

  def version
    version = Fromthepage::Application::Version
    database = ActiveRecord::Migrator.current_version

    render json: { software: version,
                   database: database }
  end


end
