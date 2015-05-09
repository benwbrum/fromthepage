class StaticController < ApplicationController

  def splash
    if !session[:welcome_lightbox]
      @show_welcome_lightbox = true
      session[:welcome_lightbox] = true
    end
  end

end