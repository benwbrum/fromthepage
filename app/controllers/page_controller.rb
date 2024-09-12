# handles administrative tasks for the page object
class PageController < ApplicationController
  require 'image_helper'
  include ImageHelper

  protect_from_forgery :except => [:set_page_title]
  before_action :authorized?, :except => [:alto_xml]

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
    # Transkribus ALTO does not include an ID on the String element, but we need one for Annotorious
    # we need to read the alto file and iterate over every string element, adding an ID attribute
    raw_alto = @page.alto_xml
    doc = Nokogiri::XML(raw_alto)

    doc.search('String').each_with_index do |string, i|
      string['ID'] = "string_#{i}"
    end

    render :plain => doc.to_xml, :layout => false, :content_type => 'text/xml'
  end

  def delete
    # We will deprecate this soon, and use convention destroy
    @page.destroy
    flash[:notice] = t('.page_deleted')
    redirect_to work_pages_tab_path(:work_id => @work.id)
  end

  def destroy
    page = Page.find(params[:id])
    page.destroy
    flash[:notice] = t('.page_deleted')
    redirect_to work_pages_tab_path(work_id: page.work_id)
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

  def edit
    # Edit route
  end

  def update
    @result = Page::Update.call(page: Page.find(params[:id]), page_params: page_params)

    if request.xhr?
      render json: {
        success: @result.success?,
        errors: @result.errors
      }
    else
      @page = @result.page
      @work = @page.work
      @collection = @work.collection

      if @result.success?
        flash[:notice] = t('.page_updated')
        redirect_to collection_edit_page_path(@collection.owner, @collection, @work, @page)
      else
        render :edit, status: :unprocessable_entity
      end
    end
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
