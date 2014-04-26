class DeedController < ApplicationController
  def list
    limit = params[:limit] || 50
    @offset = params[:offset] || 0
    if @collection
      @deeds = Deed.where([ 'collection_id = ?', @collection.id ]).order('created_at DESC').limit(limit).offset(@offset).all
    else
      @deeds = Deed.order('created_at DESC').limit(limit).offset(@offset).all
    end
  end

  def short_list
  end
end
