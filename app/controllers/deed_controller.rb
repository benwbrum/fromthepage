class DeedController < ApplicationController

  PAGES_PER_SCREEN = 50

  def list
    #get rid of col_id if no breadcrumbs
    remove_col_id

    # Build the query based on which params are available
    @deed = Deed.all
    # These shouldn't execute until they're used
    @deed = @deed.where(collection_id: @collection.id)   if @collection
    @deed = @deed.where(collection_id: @collection.ids)  if @collection_ids
    @deed = @deed.where(user_id: @user.id)               if @user
    
    # Scope for date
    if params[:start_date]
      start_date = params[:start_date].to_datetime.to_s(:db)
      @deed = @deed.where("created_at >= ?", start_date)
    end
    
    if params[:end_date]
      end_date = params[:end_date].to_datetime.to_s(:db)
      @deed = @deed.where("created_at <= ?", end_date)
    end

    @deeds = @deed.order('created_at DESC').paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
  end

end
