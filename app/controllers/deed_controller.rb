class DeedController < ApplicationController

  def list
    limit = params[:limit] || 50
    @offset = params[:offset] || 0
    if @collection
      @deeds = Deed.find(:all, 
                        {:limit => limit, 
                         :offset => @offset, 
                         :order => 'created_at DESC',
                         :conditions => [ 'collection_id = ?', @collection.id ]})
    else
      @deeds = Deed.find(:all, 
                        {:limit => limit, 
                         :offset => @offset, 
                         :order => 'created_at DESC'})
    end
  end

  def short_list
  end
end
