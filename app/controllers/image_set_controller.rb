require 'fileutils'
require 'RMagick'
include FileUtils::Verbose
include Magick
class ImageSetController < ApplicationController

  before_filter :authorized?

  def authorized?
    if logged_in? && current_user.owner
      return @image_set.owner == current_user
    end
  end
  
  
  def convert_to_work
    work = Work.new
    work.owner = current_user
    work.title = @image_set.summary
    work.description = work.title
    @image_set.titled_images.each do |titled_image|
      page = Page.new
      page.base_image = titled_image.original_file
      if File.exists?(page.base_image)
        image = Magick::ImageList.new(page.base_image)
        page.base_height = image.rows
        page.base_width = image.columns
        image = nil
        GC.start
      end   
      # width
      # height
      page.shrink_factor = @image_set.original_to_base_halvings
      page.title = titled_image.title
      work.pages << page
    end
    work.save!
    redirect_to :controller => 'work', :action => 'edit', :work_id => work.id
  end

  # TODO don't delete images if they're in a different set
  def delete
    @image_set.titled_images.each { |image| image.destroy }
    if @image_set.path 
      rm_r(@image_set.path)
    end
    @image_set.destroy
    redirect_to :controller => 'dashboard'
  end

end
