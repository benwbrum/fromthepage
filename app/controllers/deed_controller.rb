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
    else
      # show more link for site-wide/find-a-project Show More links
      if current_user && current_user.admin && params[:private]=='true'
        # let admin users see all activity if they add "private=true" to the URL
        @deed = Deed.all
      else
        # # Query ONLY allowed collections
        # scoped_collections = Collection.access_controlled(current_user).pluck(:id)
        # @deed = Deed.where(collection_id: scoped_collections)
        # due to performance problems we must redirect to the landing page
        redirect_to landing_page_path
        return
      end
    end


    # Scope for date
    if params[:start_date]
      start_date = params[:start_date].to_datetime.to_fs(:db)
      @deed = @deed.where('created_at >= ?', start_date)
    end

    if params[:end_date]
      end_date = params[:end_date].to_datetime.to_fs(:db)
      @deed = @deed.where('created_at <= ?', end_date)
    end

    @deeds = @deed.order('deeds.created_at DESC').paginate page: params[:page], per_page: PAGES_PER_SCREEN
  end
end
