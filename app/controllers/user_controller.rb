class UserController < ApplicationController
  before_action :remove_col_id, :only => [:profile, :update_profile]
  before_action :authorized?, :only => [:update_profile, :update]
  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:update, :update_profile, :api_key]

  PAGES_PER_SCREEN = 50

  def demo
    session[:demo_mode] = true;
    redirect_to dashboard_path
  end

  def feature_toggle
    feature = params[:feature]
    value = params[:value]
    session[:features] ||= {}
    if value=='enable'
      session[:features][feature]=true
    elsif value=='disable'
      session[:features][feature]=nil
    else
      if session[:features][feature]
        render :plain => "#{feature} is enabled"
      else
        render :plain => "#{feature} is disabled"
      end
      return
    end
    redirect_back :fallback_location => dashboard_role_path
  end

  def choose_locale
    new_locale = params[:chosen_locale].to_sym
    if !I18n.available_locales.include?(new_locale)
      # use the default if the above optiosn didn't work
      new_locale = I18n.default_locale
    end

    if user_signed_in?
      current_user.preferred_locale = new_locale
      current_user.save
    else
      session[:current_locale] = new_locale
    end
    redirect_back :fallback_location => dashboard_role_path
  end


  NOTOWNER = "NOTOWNER"
  def update

    # spam check
    if !@user.owner && (params[:user][:about] != NOTOWNER || params[:user][:about] != NOTOWNER)
      logger.error("Possible spam: deleting user #{@user.email}")
      @user.destroy!
      redirect_to dashboard_path
    else
      params_hash = user_params.except(:notifications)
      notifications_hash = user_params[:notifications]
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
        flash[:notice] = t('.user_updated')
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

    if @user.real_name.blank?
      @user.real_name = @user.display_name || @user.login
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


  def api_key
    @user = current_user
  end

  def generate_api_key
    @user = current_user
    @user.api_key = User.generate_api_key
    @user.save!

#    ajax_redirect_to(user_api_key_path(@user))
    render :action => :api_key, :layout => false
  end

  def disable_api_key
    @user = current_user
    @user.api_key = nil
    @user.save!
    # ajax_redirect_to(user_api_key_path(@user))
    render :action => :api_key, :layout => false
  end

  def profile
    # Find the user if it isn't already set
    @user ||= User.friendly.find(params[:id])

    if !@user.deleted || current_user.admin
      @collections_and_document_sets = @user.visible_collections_and_document_sets(current_user)
      @collection_ids = @collections_and_document_sets.map(&:id)
      @deeds = @user.deeds.includes(:note, :page, :user, :work, :collection)
                    .order('created_at DESC').paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
    else
      flash[:notice] = t('.user_deleted')
      redirect_to dashboard_path
    end

    return unless @user.owner?

    collections = @user.all_owner_collections.carousel
    sets = @user.document_sets.carousel
    @carousel_collections = (collections + sets).sample(8)
  end

  private

  def authorized?
    unless @user
      @user = User.friendly.find(params[:user_slug])
    end

    unless current_user && (@user == current_user || current_user.admin?)
      redirect_to dashboard_path
    end
  end


  def user_params
    params.require(:user).permit(:picture, :real_name, :orcid, :slug, :website, :location, :about, :preferred_locale, :help, :footer_block, notifications: [:user_activity, :owner_stats, :add_as_collaborator, :add_as_owner, :note_added, :add_as_reviewer])
  end

end
