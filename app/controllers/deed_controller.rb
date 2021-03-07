class DeedController < ApplicationController

  PAGES_PER_SCREEN = 50

  def list
    #get rid of col_id if no breadcrumbs
    remove_col_id

    # Get a list of collections that the user is allowed to view
    # And take the union of the requested Collections if requested
    if @collection
      @deed = @collection.deeds
    elsif @user
      # Scope to User as needed
      @deed = @deed.where(user_id: @user.id) if @user
    else
      # Query ONLY allowed collections
      scoped_collections = Collection.access_controlled(current_user).pluck(:id)
      @deed = Deed.where(collection_id: scoped_collections)
    end
    
    

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

  def notes
    if @collection
      @deeds = @collection.deeds.where(deed_type: DeedType::NOTE_ADDED).order('created_at DESC').includes(:note, :page, :user, :work, :collection).paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
    else
      @deeds = Deed.where(deed_type: DeedType::NOTE_ADDED).order('created_at DESC').joins(:collection).includes(:note, :page, :user, :work).where("collections.restricted = 0").paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
    end
    render :list
  end


end
