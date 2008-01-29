class DashboardController < ApplicationController
#  include AuthenticatedSystem

  def index
    redirect_to :action => 'main_dashboard'
  end

  def main_dashboard
    logger.debug("DEBUG: #{current_user.inspect}")
    if logged_in?
      @image_sets = current_user.image_sets #ImageSet.find(:all)  
    end
    @collections = Collection.find(:all)    
    @users = User.find(:all)
  end

end

