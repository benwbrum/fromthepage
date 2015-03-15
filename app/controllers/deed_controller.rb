class DeedController < ApplicationController

  def list
    limit = params[:limit] || 50
    @offset = params[:offset] || 0
    if @collection
      @deeds = Deed.where(['collection_id = ?', @collection.id]).limit(limit).offset(@offset).order('created_at DESC').all
    elsif @user
      @deeds = Deed.where(['user_id = ?', @user.id]).limit(limit).offset(@offset).order('created_at DESC').all
    else
      @deeds = Deed.limit(limit).offset(@offset).order('created_at DESC').all
    end
  end

  def short_list
  end
end
