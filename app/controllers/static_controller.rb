class StaticController < ApplicationController

  def splash
    if !session[:welcome_lightbox]
      @show_welcome_lightbox = false
      session[:welcome_lightbox] = true
    end
  end

  def metadata
    render :file => 'static/metadata.yml', :layout => false, :content_type => "text/plain"
  end

  def landing_page
    render layout: false
  end

  def special_collections
    render layout: false
  end

  def public_libraries
    render layout: false
  end

  def state_archives
    render layout: false
  end

  def digital_scholarship
    render layout: false
  end

end
