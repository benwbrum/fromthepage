class IaController < ApplicationController
  require 'open-uri'
  before_filter :load_ia_work_from_params

  def load_ia_work_from_params
    unless params[:ia_work_id].blank?
      @ia_work = IaWork.find(params[:ia_work_id])
    end
  end

  def convert
    if params[:use_ocr]
      @ia_work.use_ocr = true
      @ia_work.save!
    end

    work = @ia_work.convert_to_work
    flash[:notice] = "#{@ia_work.title} has been converted into a FromThePage work."

    redirect_to :controller => 'work', :action => 'edit', :work_id => work.id

  end


  def title_from_ocr_top
    @ia_work.title_from_ocr(:top)
    
    flash[:notice] = "Pages have been renamed with the top line of OCR text."
    redirect_to :action => 'manage', :ia_work_id => @ia_work.id
  end

  def title_from_ocr_bottom
    @ia_work.title_from_ocr(:bottom)
    
    flash[:notice] = "Pages have been renamed with the bottom line of OCR text."
    redirect_to :action => 'manage', :ia_work_id => @ia_work.id
  end

  def confirm_import
    @detail_url = params[:detail_url]
    #id = detail_url.split('/').last

    @matches = IaWork.where(:detail_url => @detail_url)
    if @matches.size() == 0
      # nothing to do here
      redirect_to :action => 'import_work', :detail_url => @detail_url
      return
    end
  end

  def import_work
    # bail if the user bailed
    if params[:commit] == 'Cancel'
      redirect_to dashboard_path
      return
    end
    detail_url = params[:detail_url]
    id = detail_url.split('/').last

    # pull relevant info about the work from here
    @ia_work = IaWork.new
    @ia_work.user = current_user
    @ia_work.detail_url = detail_url

    @ia_work.ingest_work(id)

    flash[:notice] = "#{@ia_work.title} has been imported into your staging area."

    redirect_to :action => 'manage', :ia_work_id => @ia_work.id
  end

end
