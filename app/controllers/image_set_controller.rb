require 'fileutils'
include FileUtils::Verbose
include Magick
class ImageSetController < ApplicationController

  before_filter :authorized?

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:select_target]

  def load_objects_from_params
    super
    if(params[:set_to_append_id])
      @set_to_append = ImageSet.find(params[:set_to_append_id])
    end
  end

  def authorized?
    if user_signed_in? && current_user.owner
      if @set_to_append
        redirect_to dashboard_path unless @set_to_append.owner == current_user
      end
      unless @image_set.owner == current_user
        redirect_to dashboard_path
      end
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
    if Dir.exists?(@image_set.path)
      rm_r(@image_set.path)
      @image_set.titled_images.each { |image| image.destroy }
      @image_set.destroy
    else
      flash[:error] = 'Images location path does not exist'
    end

    redirect_to :back
  end

  def select_target
    @left_sets = current_user.image_sets - [@image_set]
  end

  def append
    # expect @image_set and param[set_to_append_id]
    # load up the sets
    # now start copying images over
    # the associations will not be saved until the parent is saved.

    @image_set.titled_images << @set_to_append.titled_images
    @image_set.save!

    ajax_redirect_to :controller => 'title', :action => 'list', :image_set_id => @image_set.id
  end

end