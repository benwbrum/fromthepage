# handles administrative tasks for the page object
class Api::PageController < Api::ApiController
  require 'image_helper'
  include ImageHelper

  before_action :set_work, :only => [:create, :update]  
  before_action :set_page, :only => [:show, :update, :destroy]

  # protect_from_forgery :except => [:set_page_title]

  # def authorized?
  #   if user_signed_in? && current_user.owner
  #     if @work
  #       redirect_to dashboard_path unless @work.owner == current_user
  #     end
  #   else
  #     redirect_to dashboard_path
  #   end
  # end

  def public_actions
    return [:show]
  end

  def show    
    response_serialized_object @page
  end

  def destroy
    @page.destroy
    # flash[:notice] = 'Page has been deleted'
    # redirect_to :controller => 'work', :action => 'pages_tab', :work_id => @work.id
    render_serialized ResponseWS.ok("api.page.destroy.success",@page)
  end

  # image functions
  # def rotate
  #   orientation = params[:orientation].to_i
  #   0.upto(@page.shrink_factor) do |i|
  #     rotate_file(@page.scaled_image(i), orientation)
  #   end
  #   set_dimensions(@page)
  #   redirect_to :back
  # end

  # reordering functions
  # def reorder_page
  #   if(params[:direction]=='up')
  #     @page.move_higher
  #   else
  #     @page.move_lower
  #   end
  #   redirect_to :controller => 'work', :action => 'pages_tab', :work_id => @work.id
  # end

  def create
    @page = Page.new(params[:page])
    @page.work = @work
    subaction = params[:subaction]

    if @page.save
      # flash[:notice] = 'Page created successfully'

      if params[:image_base64]
        process_base64_image(page)
      end

      # if subaction == 'save_and_new'
      #   ajax_redirect_to({ :controller => 'dashboard', :action => 'startproject', :anchor => 'create-work' })
      # else
      #   ajax_redirect_to({ :controller => 'work', :action => 'pages_tab', :work_id => @work.id, :anchor => 'create-page' })
      # end
      render_serialized ResponseWS.ok('api.page.create.success',@page)
    else
      # render :new
      render_serialized ResponseWS.default_error
    end
  end

  def update
    page = Page.find(params[:id])
    page.work = @work
    page.update_attributes(params[:page])
    # flash[:notice] = 'Page has been successfully updated'
    
    if params[:image_base64]
      process_base64_image(page)
    end

    # redirect_to :back
    render_serialized ResponseWS.ok('api.page.update.success',page)
  end


private
  def process_base64_image(page)
    # create a new filename
    filename = "#{Rails.root}/public/images/working/upload/#{page.id}.jpg"
    dirname = File.dirname(filename)
    unless Dir.exist? dirname
      FileUtils.mkdir_p(dirname)
    end
    
    decoded_base64_content = Base64.decode64(params[:image_base64]) 
    File.open(filename, "wb") do |f|
      f.write(decoded_base64_content)
    end
    page.base_image = filename
    page.shrink_factor = 0
    set_dimensions(page)
  end

  def set_dimensions(page)
    image = Magick::ImageList.new(page.base_image)
    page.base_width = image.columns
    page.base_height = image.rows
    image = nil
    page.save!
  end
  
  def set_page
    unless @page
      @page = Page.find(params[:id])
    end
  end
  
  def set_work
    unless @work
      if Work.friendly.exists?(params[:page][:work_id])
        @work = Work.friendly.find(params[:page][:work_id])
      elsif !Work.find_by(slug: params[:page][:work_id]).nil?
        @work = Work.find_by(slug: params[:page][:work_id])
      end
    end
  end
  
end
