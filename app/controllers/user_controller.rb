class UserController < ApplicationController
  before_action :remove_col_id, :only => [:profile, :update_profile]
  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:update, :update_profile]

  def demo
    session[:demo_mode] = true;
    redirect_to dashboard_path
  end

  def update_profile
  end

  NOTOWNER = "NOTOWNER"
  def update
    # spam check
    if !@user.owner && (params[:user][:about] != NOTOWNER || params[:user][:about] != NOTOWNER)
      logger.error("Possible spam: deleting user #{@user.email}")
      @user.destroy!
      redirect_to dashboard_path
    else 
      params_hash = params[:user].except(:notifications)
      notifications_hash = params[:user][:notifications]
      params_hash.delete_if { |k,v| v == NOTOWNER }
      params_hash[:dictation_language] = params[:dialect]
      
      if params_hash[:slug] == ""
        @user.update(params_hash.except(:slug))
        login = @user.login.parameterize
        @user.update(slug: login)
      else
        @user.update(params_hash)
      end
        @user.notification.update(notifications_hash)

      if @user.save!
        flash[:notice] = "User profile has been updated"
        ajax_redirect_to({ :action => 'profile', :user_id => @user.slug, :anchor => '' })
      else
        render :action => 'update_profile'
      end
    end
  end

  def update_profile
    unless @user
      @user = User.friendly.find(params[:user_slug])
    end
    
    # Set dictation language to default (en-US) if it doesn't exist
    lang = !@user.dictation_language.blank? ? @user.dictation_language : "en-US"
    # Find the language portion of the language/dialect or set to nil
    part = lang.split('-').first
    # Find the index of the language in the array (transform to integer)
    @lang_index = Collection::LANGUAGE_ARRAY.size.times
      .select {|i| Collection::LANGUAGE_ARRAY[i].include?(part)}[0]
    # Then find the index of the nested dialect within the language array
    int = Collection::LANGUAGE_ARRAY[@lang_index].size.times
      .select {|i| Collection::LANGUAGE_ARRAY[@lang_index][i].include?(lang)}[0]
    # Transform to integer and subtract 2 because of how the array is nested
    @dialect_index = !int.nil? ? int-2 : nil
  end

  def profile
    #find the user if it isn't already set
    unless @user
      @user = User.friendly.find(params[:id])
    end
    if !@user.deleted || current_user.admin 
      @collections_and_document_sets = @user.owned_collection_and_document_sets
      @collection_ids = @collections_and_document_sets.map {|collection| collection.id}
      @deeds = Deed.where(collection_id: @collection_ids).order("created_at DESC").limit(10)
      @notes = @user.notes.limit(10)
      @page_versions = @user.page_versions.includes(page: :work).limit(10)
      @article_versions = @user.article_versions.limit(10).joins(:article).includes(article: :categories)
    else
      flash[:notice] = "User profile has been deleted"
      redirect_to dashboard_path
    end
    if @user.owner?
      collections = @user.all_owner_collections.carousel
      sets = @user.document_sets.carousel
      @carousel_collections = (collections + sets).sample(8)
    end
  end

  def record_deed
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    deed.collection = @collection
    deed.deed_type = DeedType::NOTE_ADDED
    deed.user = current_user
    deed.save!
  end

end
