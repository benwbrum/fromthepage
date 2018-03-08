require 'gamification_helper'

class RegistrationsController < Devise::RegistrationsController

  def new
    super
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
      # call GamificationHelper
      GamificationHelper.registerEvent(@user.email)
      flash[:notification] = {'title':'New Badge Obtained!','message':'I was here!'}

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
    session[:user_return_to] || root_path
  end

end
