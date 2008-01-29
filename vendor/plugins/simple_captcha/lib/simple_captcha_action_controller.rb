require 'action_controller'
require 'pstore'

module SimpleCaptcha #:nodoc
  
  module ControllerHelpers #:nodoc
    
    include ConfigTasks #:nodoc
    
    # This method is to validate the simple captcha in controller.
    # It means when the captcha is controller based i.e. :object has not been passed to the method show_simple_captcha.
    #
    # *Example*
    #
    # If you want to save an object say @user only if the captcha is validated then do like this in action...
    #
    #  if simple_captcha_valid?
    #   @user.save
    #  else
    #   flash[:notice] = "captcha did not match"
    #   redirect_to :action => "myaction"
    #  end
    def simple_captcha_valid?
      return true if RAILS_ENV == 'test'
      if params[:captcha]
        data = PStore.new(CAPTCHA_DATA_PATH + "data")
        data.transaction do
          @ret = data[create_code] == params[:captcha].delete(" ").upcase
        end
        return @ret
      else
        return false
      end
    end
    
  end
  
end


ActionController::Base.class_eval do
  include SimpleCaptcha::ControllerHelpers
end
