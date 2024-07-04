class DeedController < ApplicationController

  PAGES_PER_SCREEN = 50

  def list
    # get rid of col_id if no breadcrumbs
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
        @deed = @user.deeds.includes(:note, :page, :user, :work, :collection).paginate page: params[:page], per_page: PAGES_PER_SCREEN
      end
    elsif current_user&.admin && params[:private] == 'true'
      # show more link for site-wide/find-a-project Show More links
      @deed = Deed.all
    # let admin users see all activity if they add "private=true" to the URL
    else
      # Query ONLY allowed collections
      scoped_collections = Collection.access_controlled(current_user).pluck(:id)
      @deed = Deed.where(collection_id: scoped_collections)
    end

    # Scope for date
    if params[:start_date]
      start_date = Time.zone.parse(params[:start_date]).to_fs(:db)
      @deed = @deed.where(created_at: start_date..)
    end

    if params[:end_date]
      end_date = Time.zone.parse(params[:end_date]).to_fs(:db)
      @deed = @deed.where(created_at: ..end_date)
    end

    @deeds = @deed.order('deeds.created_at DESC').paginate page: params[:page], per_page: PAGES_PER_SCREEN
  end

end
