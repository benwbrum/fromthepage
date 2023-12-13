# handles administrative tasks for the page object
class PageController < ApplicationController
  require 'image_helper'
  include ImageHelper

  protect_from_forgery :except => [:set_page_title]
  before_action :authorized?

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:new, :create]

  def authorized?
    if user_signed_in?
      if @work
        redirect_to dashboard_path unless current_user.like_owner?(@work)
      end
    else
      redirect_to dashboard_path
    end
  end

  def alto_xml
    render :plain => @page.alto_xml, :layout => false, :content_type => 'text/xml'
  end
  
  def delete
    @page.destroy
    flash[:notice] = t('.page_deleted')
    redirect_to work_pages_tab_path(:work_id => @work.id)
  end

  # image functions
  def rotate
    orientation = params[:orientation].to_i
    0.upto(@page.shrink_factor) do |i|
      rotate_file(@page.scaled_image(i), orientation)
    end
    set_dimensions(@page)
    redirect_back fallback_location: @page
  end


  # reordering functions
  def reorder_page
    if(params[:direction]=='up')
      @page.move_higher
    else
      @page.move_lower
    end
    redirect_to work_pages_tab_path(:work_id => @work.id)
  end

  # new page functions
  def new
    @page = Page.new
    @page.title = @work.suggest_next_page_title
    @page.work = @work
  end

  def create
    @page = Page.new(page_params)
    subaction = params[:subaction]
    @work.pages << @page

    if @page.save
      flash[:notice] = t('.page_created')

      if page_params[:base_image]
        process_uploaded_file(@page, page_params[:base_image])
      end

      if subaction == 'save_and_new'
        ajax_redirect_to({ :controller => 'dashboard', :action => 'startproject', :anchor => 'create-work' })
      else
        ajax_redirect_to({ :controller => 'work', :action => 'pages_tab', :work_id => @work.id, :anchor => 'create-page' })
      end
    else
      render :new
    end
  end

  def update
    page = Page.find(params[:id])
    attributes = page_params.to_h.except("base_image")
    if page_params[:status].blank?
      attributes['status'] = nil
    end   
    page.update_columns(attributes) # bypass page version callbacks
    flash[:notice] = t('.page_updated')
    page.work.work_statistic.recalculate if page.work.work_statistic

    if params[:page][:base_image]
      process_uploaded_file(page, page_params[:base_image])
    end

    redirect_back fallback_location: page
  end


  private

  def process_uploaded_file(page, image_file)
    # create a new filename
    filename = "#{Rails.root}/public/images/working/upload/#{page.id}.jpg"

    dirname = File.dirname(filename)
    unless Dir.exist? dirname
      FileUtils.mkdir_p(dirname)
    end

    FileUtils.mv(image_file.tempfile, filename)
    FileUtils.chmod("u=wr,go=r", filename)
    page.base_image = filename
    page.shrink_factor = 0
    set_dimensions(page)
    #reduce_by_one(page)
  end

  def reduce_by_one(page)
    page.shrink_factor = page.shrink_factor + 1
    shrink_file(page.scaled_image(0),
                page.scaled_image(page.shrink_factor),
                page.shrink_factor)
    page.save!
  end

  def set_dimensions(page)
    image = Magick::ImageList.new(page.base_image)
    page.base_width = image.columns
    page.base_height = image.rows
    image = nil
    page.save!
  end

  def page_params
    params.require(:page).permit(:page, :title, :base_image, :status, :translation_status)
  end

end
