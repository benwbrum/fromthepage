class DeedController < ApplicationController

  PAGES_PER_SCREEN = 50

  def list
    #get rid of col_id if no breadcrumbs
    remove_col_id

    # Get a list of collections that the user is allowed to view
    # And take the union of the requested Collections if requested
    scoped_collections = Collection.access_controlled(current_user).pluck(:id)
    scoped_collections &= [@collection.id] if @collection 
    
    # Query ONLY allowed collections
    @deed = Deed.where(collection_id: scoped_collections)
    
    # Scope to User as needed
    @deed = @deed.where(user_id: @user.id) if @user

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
