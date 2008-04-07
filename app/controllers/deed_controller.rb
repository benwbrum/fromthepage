class DeedController < ApplicationController

  def list
    limit = params[:limit] || 50
    @offset = params[:offset] || 0
    @deeds = Deed.find(:all, :limit => limit, :offset => @offset, :order => 'created_at DESC')
  end

  def short_list
  end
end
