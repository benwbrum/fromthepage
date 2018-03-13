class DeedController < ApplicationController

  PAGES_PER_SCREEN = 50

  def list
    #get rid of col_id if no breadcrumbs
    if session[:col_id]
      session[:col_id] = nil
    end
    condition = []

    if @collection
      condition = ['collection_id = ?', @collection.id]
    elsif @user
      condition = ['user_id = ?', @user.id]
    elsif @collection_ids
      @deeds = Deed.where(collection_id: @collection_ids).order('created_at DESC').paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
      return
    end
    @deeds = Deed.where(condition).order('created_at DESC').paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
  end

end
