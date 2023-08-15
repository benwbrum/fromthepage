class RegistrationsController < Devise::RegistrationsController

  def new
    super
  end

  def owner_new
    @owner = User.where(slug: params[:user_slug]).first
    new
  end

  def new_trial
    new
  end

  def destroy
    resource.soft_delete
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message :notice, :destroyed if is_flashing_format?
    yield resource if block_given?
    respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name)}
  end

  def create
    unless params[:owner_slug].blank?
      @owner = User.where(slug: params[:owner_slug]).first
    end

    #merge the new user information into the guest user id to change into normal user
    if current_user && current_user.guest?
      @user = current_user
      @user.update(sign_up_params)
      @user.guest = false
      
    else
      @user = build_resource(sign_up_params)
    end

    #this is the default Devise code
    yield resource if block_given?
      
    if check_recaptcha(model: @user) && @user.save
      # Record the `joined` deed based on Ahoy Visit
      join_collection = joined_from_collection(current_visit.id)
      unless join_collection.nil?
        @user.join_collection(join_collection)
        new_mobile_user = helpers.mobile_device?
      end

      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        session[:new_mobile_user] = new_mobile_user
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
      #set the guest_user_id of the session to nil for user login/out
      if session[:guest_user_id]
        session[:guest_user_id] = nil
      end
      
      if @user.owner
        @user.account_type="Trial"
        @user.save
        alert_intercom
      end

      update_search_attempt_user(@user)
    else
      clean_up_passwords resource
      @validatable = devise_mapping.validatable?
      if @validatable
        @minimum_password_length = resource_class.password_length.min
      end
      respond_with resource
    end
  end

  def update
    @user.login = sign_up_params[:login]
    @user.email = sign_up_params[:email]
    @user.real_name = sign_up_params[:real_name]
    unless sign_up_params[:password].blank?
      @user.password=sign_up_params[:password]
      @user.password_confirmation=sign_up_params[:password_confirmation]
    end

    if @user.save
      bypass_sign_in(@user)
      flash[:notice] = t('user.update.user_updated')
      ajax_redirect_to({ :controller => 'user', :action => 'profile', :user_id => @user.slug, :anchor => '' })
    else
      render :controller => 'user', :action => 'edit'
    end
  end


  def set_saml
    institution = saml_provider_param
    redirect_to user_omniauth_authorize_path(institution)  #go to users/auth/saml/instution_name
  end

  def choose_saml
  end


  def alert_intercom()
    if INTERCOM_ACCESS_TOKEN
        intercom=Intercom::Client.new(token:INTERCOM_ACCESS_TOKEN)
        contact = intercom.users.create(email: current_user.email)
        tag = intercom.tags.tag(name: 'trial', users: [{email: current_user.email}])
    end
  end

  #redirect new sign up back to starting page
  def after_sign_up_path_for(resource)
    if @user.owner
      # Always send new owners to their dashboard for analytics purposes
      "#{dashboard_owner_path}#freetrial" 
    else
      # New users should be returned to where they were or to their dashboard/watchlist
      if session[:user_return_to] && !landing_pages.include?(session[:user_return_to])
        session[:user_return_to]
      elsif @owner
        user_profile_path(@owner)
      else
        dashboard_watchlist_path
      end
    end
  end

  def after_update_path_for(resource)
    edit_registration_path(resource)
  end

  def check_recaptcha(options)
    return verify_recaptcha(options) if RECAPTCHA_ENABLED
    true
  end

  private

  def sign_up_params
    params.require(:user).permit(:login, :real_name, :owner, :activity_email, :paid_date, :display_name, :email, :password, :password_confirmation)
  end

  def saml_provider_param
    params.require(:institution)
  end

  def joined_from_collection(visit_id)
    first_event = Ahoy::Event.where(visit_id: visit_id).first
    collection = first_event.properties["collection_id"] || nil
    return collection
  end

  def landing_pages
    [
      signup_path,
      root_path,
      special_collections_path,
      public_libraries_path,
      digital_scholarship_path,
      state_archives_path
    ]
  end


end
