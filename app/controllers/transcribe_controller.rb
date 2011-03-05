class TranscribeController  < ApplicationController

  include AbstractXmlController

  require 'RMagick'
  require 'rexml/document'
  include Magick
  before_filter :authorized?, :except => :zoom
  protect_from_forgery :except => [:zoom, :unzoom]
  
  def authorized?
    unless logged_in? && current_user.can_transcribe?(@work)
      redirect_to  :action => 'display_page', :page_id => @page.id, :controller => 'display'
    end
  end

  def mark_page_blank
    @page.status = Page::STATUS_BLANK
    @page.save
    @work.work_statistic.recalculate if @work.work_statistic
    redirect_to :controller => 'display', :action => 'display_page', :page_id => @page.id
  end

  def save_transcription
    old_link_count = @page.page_article_links.count
    @page.attributes=params[:page]
    if params['save']
      if @page.save
        record_deed
        # use the new links to blank the graphs
        @page.clear_article_graphs
        
        new_link_count = @page.page_article_links.count
        logger.debug("DEBUG old_link_count=#{old_link_count}, new_link_count=#{new_link_count}")
        if old_link_count == 0 && new_link_count > 0
          record_index_deed
        end
        @work.work_statistic.recalculate if @work.work_statistic
        #redirect_to :action => 'display_page', :page_id => @page.id, :controller => 'display'
        redirect_to :action => 'assign_categories', :page_id => @page.id
      else
        flash[:error] = @page.errors[:base].join('<br />')
        render :action => 'display_page'
      end    
    elsif params['preview']
      @preview_xml = @page.generate_preview
      render :action => 'display_page'
    elsif params['autolink']
      @page.source_text = autolink(@page.source_text)
      render :action => 'display_page'
    end
  end


  def assign_categories
    # look for uncategorized articles
    for article in @page.articles 
	  if article.categories.length == 0
	    render :action => 'assign_categories'
	    return
      end
    end
    # no uncategorized articles found, skip to display
    redirect_to  :action => 'display_page', :page_id => @page.id, :controller => 'display'
  end

  # TODO: move this to a module, check that anonymous/non-scribe users can zoom,
  # use tempfiles
  def zoom
    click_x = params[:x].to_f
    click_y = params[:y].to_f
    old_x_offset = params[:x_offset].to_f
    old_y_offset = params[:y_offset].to_f
    old_scale = params[:current_scale].to_i
    new_scale = old_scale - 1
    
    # display values are the sizes to crop and show
    display_width = @page.base_width / ( 2 ** @page.shrink_factor)
    display_height = @page.base_height / ( 2 ** @page.shrink_factor)
    
    # transpose the click position to full size
    full_x = (old_x_offset + click_x) * (2 ** old_scale)
    full_y = (old_y_offset + click_y) * (2 ** old_scale)
    
    # transpose the click position to the new scale
    scaled_x = full_x / (2 ** new_scale)
    scaled_y = full_y / (2 ** new_scale)
    
    # come up with left, top margins
    crop_x = scaled_x - (display_width/2)
    crop_y = scaled_y - (display_height/2)

#    # problem: the images are displaying too high and left.
#
#    logger.debug("DEBUG: values pre-adjustment:")
#    logger.debug("DEBUG:    click_x: #{click_x}")
#    logger.debug("DEBUG:    click_y: #{click_y}")
#    logger.debug("DEBUG:    old_x_offset: #{old_x_offset}")
#    logger.debug("DEBUG:    old_y_offset: #{old_y_offset}")
#    logger.debug("DEBUG:    old_scale: #{old_scale}")
#    logger.debug("DEBUG:    new_scale: #{new_scale}")
#    logger.debug("DEBUG:    display_width: #{display_width}")
#    logger.debug("DEBUG:    display_height: #{display_height}")
#    logger.debug("DEBUG:    full_x: #{full_x}")
#    logger.debug("DEBUG:    full_y: #{full_y}")
#    logger.debug("DEBUG:    scaled_x: #{scaled_x}")
#    logger.debug("DEBUG:    scaled_y: #{scaled_y}")
#    logger.debug("DEBUG:    crop_x: #{crop_x}")
#    logger.debug("DEBUG:    crop_y: #{crop_y}")

    # adjust to top, left borders
    if(crop_x < 0)
      # the click was near a border
      # adjust the crop to zero
      crop_x = 0
    end
    if(crop_y < 0)
      # the click was near a border
      # adjust the crop to zero
      crop_y = 0
    end
#    logger.debug("DEBUG:    crop_x (post-origin-adjustment): #{crop_x}")
#    logger.debug("DEBUG:    crop_y (post-origin-adjustment): #{crop_y}")

    # adjust to bottom, left borders
    scaled_width = @page.base_width / (2 ** new_scale)
    scaled_height = @page.base_height / (2 ** new_scale)
    if(crop_x + display_width > scaled_width)
      crop_x = scaled_width - display_width
    end
    if(crop_y + display_height > scaled_height)
      crop_y = scaled_height - display_height
    end
#    logger.debug("DEBUG:    scaled_width: #{scaled_width}")
#    logger.debug("DEBUG:    scaled_height: #{scaled_height}")
#    logger.debug("DEBUG:    crop_x (post-edge-adjustment): #{crop_x}")
#    logger.debug("DEBUG:    crop_y (post-edge-adjustment): #{crop_y}")
    
    # actually crop the image
    scaled = Magick::ImageList.new(@page.scaled_image(new_scale))
    crop = scaled.crop(crop_x, crop_y, display_width, display_height)
    @zoomed_file = @page.scaled_image(new_scale).sub(/.jpg/, ".zoom.jpg")
    logger.debug("DEBUG:    writing #{@zoomed_file}")
    
    val = crop.write(@zoomed_file)
    unless val
      logger.debug("DEBUG:    could not write #{@zoomed_file}")
    end
    
    # set variables to pass to the client
    @scale = new_scale    
    @x_offset = crop_x
    @y_offset = crop_y
  end  
  
  def unzoom
    @zoomed_files = @page.base_image.sub(/.jpg/, "*.zoom.jpg")
    logger.debug("DEBUG: rm #{@zoomed_files}")
    Dir.glob(@zoomed_files) do |filename|
      logger.debug("DEBUG: unlinking #{filename}")
      File.unlink(filename)
    end
    render :text => ""  
  end

protected

  def record_deed
    deed = stub_deed
    current_version = @page.page_versions[0]
    if current_version.page_version > 1
      deed.deed_type = Deed::PAGE_EDIT
    else
      deed.deed_type = Deed::PAGE_TRANSCRIPTION
    end
    deed.user = current_user
    deed.save!
  end
  
  def stub_deed
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    deed.collection = @collection
    deed
  end
  
  def record_index_deed
    deed = stub_deed
    deed.deed_type = Deed::PAGE_INDEXED
    deed.user = current_user
    deed.save!
  end
end
