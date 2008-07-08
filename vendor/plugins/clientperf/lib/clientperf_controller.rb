class ClientperfController < ActionController::Base
  def index
    ClientperfUri.destroy_all ["updated_at < ?", 1.year.ago]
    @uris = ClientperfUri.find(:all, :include => :clientperf_results)
  end
  
  def show
    @uri = ClientperfUri.find(params[:id], :include => :clientperf_results)
    @page_title = @uri.uri
  end
  
  def measure
    milliseconds = params[:e].to_i - params[:b].to_i rescue nil
    if milliseconds && params[:u]
      uri = ClientperfUri.find_or_create_by_uri(params[:u])
      ClientperfResult.create(:milliseconds => milliseconds, :clientperf_uri => uri)
    end
    render :nothing => true
  end
  
  private
  
  def authenticate
    return true if action_name == 'measure'
    
    config = ClientperfConfig.new
    if config.has_auth?
      authenticate_or_request_with_http_basic do |user_name, password|
        user_name == config['username'] && password == config['password']
      end
    end
  end
end