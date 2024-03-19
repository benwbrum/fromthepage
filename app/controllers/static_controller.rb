class StaticController < ApplicationController

  def splash
    if !session[:welcome_lightbox]
      @show_welcome_lightbox = false
      session[:welcome_lightbox] = true
    end
  end

  def metadata
    render :file => Rails.root.join('app/views/static', 'metadata.yml'), :layout => false, :content_type => "text/plain"
  end

  def landing_page
    if user_signed_in? && params[:logo] != 'true' 
      if current_user.admin
        return redirect_to admin_path
      elsif current_user.owner
        return redirect_to dashboard_owner_path
      else
        return redirect_to dashboard_watchlist_path
      end
    end
    render layout: false
  end

  def signup
    render layout: false
  end

  def transcription_archives
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
