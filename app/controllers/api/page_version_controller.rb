class Api::PageVersionController < Api::ApiController
  
  before_action :set_page, only: [:list_by_page]
  
  def list_by_page
    response_serialized_object(@page.page_versions)
  end
  
  private
    def set_page
      @page = Page.find(params[:page_id])
    end
    
end
