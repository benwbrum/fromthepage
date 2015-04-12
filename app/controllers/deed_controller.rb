class DeedController < ApplicationController

  PAGES_PER_SCREEN = 50

  def list
    condition = []

    if @collection
      condition = ['collection_id = ?', @collection.id]
    elsif @user
      condition = ['user_id = ?', @user.id]
    end

    @deeds = Deed.where(condition).order('created_at DESC').paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
  end

end
