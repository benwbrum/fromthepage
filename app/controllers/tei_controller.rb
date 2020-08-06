class TeiController < DisplayController

  def display_page
    params[:format] = 'xml' if params[:format].blank?

    render :content_type => "application/xml"
  end
end
