class StaticController < ApplicationController

  def splash
    if !session[:welcome_lightbox]
      @show_welcome_lightbox = false
      session[:welcome_lightbox] = true
    end
  end

end