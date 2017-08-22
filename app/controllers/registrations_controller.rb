class RegistrationsController < Devise::RegistrationsController

  def new
    super
  end

  def new_trial
    new
  end

  def create
    #merge the new user information into the guest user id to change into normal user
    if current_user && current_user.guest?
      @user = current_user
      @user.update_attributes(sign_up_params)
      @user.guest = false

    else
      @user = build_resource(sign_up_params)
    end
    resource_saved = @user.save
    #this is the default Devise code
    yield resource if block_given?
    
    if resource_saved
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
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

    else
      clean_up_passwords resource
      @validatable = devise_mapping.validatable?
      if @validatable
        @minimum_password_length = resource_class.password_length.min
      end
      respond_with resource
    end
  end

  #redirect new sign up back to starting page
  def after_sign_up_path_for(resource)
    unless @user.owner
      session[:user_return_to] || root_path
    else
      dashboard_owner_path
    end
  end

end
