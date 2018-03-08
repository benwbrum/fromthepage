class Api::UserController < Api::ApiController



  def update_profile
  end

  NOTOWNER = "NOTOWNER"
  def update
    puts "-------------------------"
    puts "update"
    # spam check
    @user = current_user
    @user = User.friendly.find(params[:id])
    puts current_user
    if !@user.owner && (params[:user][:about] != NOTOWNER || params[:user][:about] != NOTOWNER)
      logger.error("Possible spam: deleting user #{@user.email}")
      @user.destroy!
      
    else 
      params[:user].delete_if { |k,v| v == NOTOWNER }
      if params[:user][:slug] == ""
        @user.update(params[:user].except(:slug))
        login = @user.login.parameterize
        @user.update(slug: login)
      else
        @user.update(params[:user])
      end
      if @user.save!
        render_serialized ResponseWS.ok('api.user.update.success',@user)
      else
       render_serialized ResponseWS.default_error
      end
    end
  end

  def profile
    unless @user
      @user = User.friendly.find(params[:id])
    end
    @collections = @user.owned_collection_and_document_sets
    @collection_ids = @collections.map {|collection| collection.id}
    @deeds = Deed.where(collection_id: @collection_ids).order("created_at DESC").limit(10)
    @notes = @user.notes.limit(10)
    @page_versions = @user.page_versions.includes(page: :work).limit(10)
    @article_versions = @user.article_versions.limit(10).joins(:article).includes(article: :categories)
  end

  def record_deed
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    deed.collection = @collection
    deed.deed_type = Deed::NOTE_ADDED
    deed.user = current_user
    deed.save!
  end

end
