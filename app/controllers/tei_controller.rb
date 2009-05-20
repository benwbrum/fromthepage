class TeiController < DisplayController
  
  def display_page
    params[:format] = 'xml' if params[:format].blank?
    
#    render :text => 'done'

  end
end
