# handles administrative tasks for the page object
class PageController < ApplicationController
  require 'image_helper'
  include ImageHelper

  protect_from_forgery :except => [:set_page_title]
  before_filter :authorized?

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:new, :create]

  def authorized?
    if user_signed_in? && current_user.owner
      if @work
        redirect_to dashboard_path unless @work.owner == current_user
      end
    else
      redirect_to dashboard_path
    end
  end

  def delete
    @page.destroy
    flash[:notice] = 'Page has been deleted'
    redirect_to :controller => 'work', :action => 'pages_tab', :work_id => @work.id
  end

  # image functions
  def rotate
    orientation = params[:orientation].to_i
    0.upto(@page.shrink_factor) do |i|
      rotate_file(@page.scaled_image(i), orientation)
    end
    set_dimensions(@page)
    redirect_to :back
  end

  def reduce
    reduce_by_one(@page)
    set_dimensions(@page)
    redirect_to :back
  end

  def enlarge
    @page.shrink_factor = @page.shrink_factor - 1
    @page.save!
    set_dimensions(@page)
    redirect_to :back
  end

  # reordering functions
  def reorder_page
    if(params[:direction]=='up')
      @page.move_higher
    else
      @page.move_lower
    end
    redirect_to :controller => 'work', :action => 'pages_tab', :work_id => @work.id
  end

  # new page functions
  def new
    @page = Page.new
    @page.title = @work.suggest_next_page_title
    @page.work = @work
  end

  def create
    page = Page.new(params[:page])
    subaction = params[:subaction]
    if subaction == 'cancel'
      redirect_to :controller => 'display', :action => 'read_work', :work_id => @work.id
      return
    end
    page.work = @work
    if params[:page][:base_image]
      process_uploaded_file(page,  page.base_image)
    end


    if page.save
      flash[:notice] = 'Page created successfully'
      if subaction == 'save_and_new'
        ajax_redirect_to({ :controller => 'work', :action => 'new', :collection_id => @work.collection })
      else
        ajax_redirect_to({ :controller => 'page', :action => 'new', :work_id => @work.id })        
      end
    else
      render :new
    end
  end

  def update
    page = Page.find(params[:id])
    page.update_attributes(params[:page])
    flash[:notice] = 'Page has been successfully updated'

    if params[:page][:base_image]
      process_uploaded_file(page, page.base_image)
    end

    redirect_to :back
  end




  private
  def process_uploaded_file(page, filename)
    if filename.blank?
      # create a new filename
      filename = "#{Rails.root}/public/images/working/upload/#{page.id}.jpg"
    end
    dirname = File.dirname(filename)
    unless Dir.exist? dirname
      FileUtils.mkdir_p(dirname)
    end
    File.open(filename, "wb") do |f|
      f.write(params[:page][:base_image].read)
    end
    page.base_image = filename
    page.shrink_factor = 0
    set_dimensions(page)
#    reduce_by_one(page)
    
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

end