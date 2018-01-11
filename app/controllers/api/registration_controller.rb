require 'gamification_helper'
class Api::RegistrationController < Api::ApiDeviceRegistrationController

  def new
    super
  end
  def flash
    Flash.new
  end

  class Flash

    def []=(k, v)
    end

    def [](k)
    end

    def alert=(message)
    end

    def notice=(message)
    end
  end

  #endpoints

  def create
    if current_user && current_user.guest?
      @user = current_user
      @user.update_attributes(sign_up_params)
      @user.guest = false
    else
      puts "else"
      puts params[:user]
      @user = build_resource(params[:user])
    end
    puts @user
    resource_saved = @user.save
    yield resource if block_given?
    if resource_saved
      # call GamificationHelper
     # GamificationHelper.registerEvent(@user.email)

      render_serialized ResponseWS.ok('api.registration.create.success',@user)
    else
      clean_up_passwords resource
      @validatable = devise_mapping.validatable?
      if @validatable
        @minimum_password_length = resource_class.password_length.min
      end
      puts "-------"
      puts resource.errors.full_messages.to_sentence
      render_serialized ResponseWS.error(resource.errors.full_messages.to_sentence,nil)
    end
  end



end
