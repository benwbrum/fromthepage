# handles administrative tasks for the page object
class PageController < ApplicationController
  require 'RMagick'
  include ImageHelper

  before_filter :authorized?

  def authorized?
    if logged_in? && current_user.owner
      if @work
        redirect_to :controller => 'dashboard' unless @work.owner == current_user
      end
    else
      redirect_to :controller => 'dashboard' 
    end
  end


  in_place_edit_for :page, :title
  
  protect_from_forgery :except => [:set_page_title]

  def delete
    @page.destroy
    redirect_to :controller => 'work', :action => 'edit', :work_id => @work.id
  end


  # image tab functions

  def rotate
    orientation = params[:orientation].to_i
    0.upto(@page.shrink_factor) do |i|
      rotate_file(@page.scaled_image(i), orientation)
    end
    set_dimensions(@page)
    redirect_to :action => 'image_tab', :page_id => @page.id
  end

  def reduce
    reduce_by_one(@page)
    set_dimensions(@page)
    redirect_to :action => 'image_tab', :page_id => @page.id
  end

  def enlarge
    @page.shrink_factor = @page.shrink_factor - 1
    @page.save!
    set_dimensions(@page)
    redirect_to :action => 'image_tab', :page_id => @page.id
  end

  def upload
    filename = @page.base_image
    if filename == nil || filename == ""
      # create a new filename
      filename = "#{Rails.root}/public/images/working/upload/#{@page.id}.jpg"
    end
    File.open(filename, "wb") do |f| 
      f.write(params['page']['base_image'].read)
    end
    @page.base_image = filename
    @page.shrink_factor = 0
    set_dimensions(@page)
    reduce_by_one(@page)
    reduce_by_one(@page)
    redirect_to :action => 'image_tab', :page_id => @page.id
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
    @page.work = @work
  end
  
  def create
    page = Page.new(params[:page])
    page.save!
    redirect_to :controller => 'work', :action => 'pages_tab', :work_id => @work.id  
  end

private

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
