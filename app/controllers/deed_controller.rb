class DeedController < ApplicationController

  PAGES_PER_SCREEN = 50

  def list
    #get rid of col_id if no breadcrumbs
    remove_col_id

    if @collection
      # show more link on collections and document sets
      @deed = @collection.deeds
    elsif @user
      if @user.owner?
        # owner profile show more link
        @deed = Deed.where(collection_id: @user.all_owner_collections.ids)
      else
        # user activity stream show more link
        @deed = @user.deeds.includes(:note, :page, :user, :work, :collection).paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
      end
    else
      # show more link for site-wide/find-a-project Show More links
      if current_user && current_user.admin && params[:private]=='true'
        # let admin users see all activity if they add "private=true" to the URL
        @deed = Deed.all
      else
        # Query ONLY allowed collections
        scoped_collections = Collection.access_controlled(current_user).pluck(:id)
        @deed = Deed.where(collection_id: scoped_collections)
      end
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

    @deeds = @deed.order('deeds.created_at DESC').paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
    @paginate = true
  end

  def notes
    if @collection
      @deeds = @collection.deeds.where(deed_type: DeedType::NOTE_ADDED).order('deeds.created_at DESC').includes(:note, :page, :user, :work, :collection)
      @paginate = false
    else
      @deeds = Deed.where(deed_type: DeedType::NOTE_ADDED).order('deeds.created_at DESC').joins(:collection).includes(:note, :page, :user, :work).where("collections.restricted = 0").paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
      @paginate = true
    end
    render :list
  end


end
