class TranscribeController  < ApplicationController

  include AbstractXmlController

  require 'RMagick'
  require 'rexml/document'
  include Magick
  before_filter :authorized?

  def authorized?
    if logged_in? 
      current_user.can_transcribe?(@work)
    else
      false
    end
  end

  def save_transcription
    @page.attributes=params[:page]
    if params['save']
      @page.save!
      # use the new links to blank the graphs
      @page.clear_article_graphs
      #redirect_to :action => 'display_page', :page_id => @page.id, :controller => 'display'
      redirect_to :action => 'assign_categories', :page_id => @page.id
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

    # adjust to bottom, left borders
    scaled_width = @page.base_width / (2 ** new_scale)
    scaled_height = @page.base_height / (2 ** new_scale)
    if(crop_x + display_width > scaled_width)
      crop_x = scaled_width - display_width
    end
    if(crop_y + display_height > scaled_height)
      crop_y = scaled_height - display_height
    end
    
    # actually crop the image
    scaled = Magick::ImageList.new(@page.scaled_image(new_scale))
    crop = scaled.crop(crop_x, crop_y, display_width, display_height)
    @zoomed_file = @page.scaled_image(new_scale).sub(/.jpg/, ".zoom.jpg")
    crop.write(@zoomed_file)

    # set variables to pass to the client
    @scale = new_scale    
    @x_offset = crop_x
    @y_offset = crop_y
  end  

protected

end
