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

end