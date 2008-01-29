require 'active_record'

module SimpleCaptcha #:nodoc
  
  module ModelHelpers #:nodoc
    
    # To implement model based simple captcha use this method in the model as...
    #
    #  class User < ActiveRecord::Base
    #
    #    apply_simple_captcha :message => "my customized message"
    #
    #  end
    #
    # Customize the error message by using :message, the default message is "Captcha did not match". 
    # As in the applications captcha is needed with a very few cases like signing up the new user, but
    # not every time you need to authenticate the captcha with @user.save. So as to maintain simplicity
    # here we have the explicit method to save the instace with captcha validation as...
    #
    # * to validate the instance
    #  
    #  @user.valid_with_captcha?  # whene captcha validation is required.
    #
    #  @user.valid?               # when captcha validation is not required.
    #
    # * to save the instance
    #
    #  @user.save_with_captcha   # whene captcha validation is required.
    #
    #  @user.save                # when captcha validation is not required.
    def apply_simple_captcha(options = {})
      module_eval do
        require 'pstore'
        include SimpleCaptcha::Config
        attr_accessor :captcha, :captcha_code, :authenticate_with_captcha
        alias_method :valid_without_captcha?, :valid?
        alias_method :save_without_captcha, :save
      end
      @captcha_invalid_message = (options[:message].nil? || options[:message].empty?) ?  " image did not match with text" : options[:message]
      module_eval(turing_valid_method)
      module_eval(turing_save_method)
    end
    
    def turing_valid_method #:nodoc
      ret = <<-EOS
      def valid?
        return valid_without_captcha? if RAILS_ENV == 'test'
        if authenticate_with_captcha
          ret = valid_without_captcha?
          data = PStore.new(CAPTCHA_DATA_PATH + "data")
          data.transaction do
            @stored_captcha = data[captcha_code] rescue nil
          end
          if captcha and captcha.upcase.delete(" ") == @stored_captcha
            ret = ret and true
          else
            ret = false
            self.errors.add(:captcha, "#{@captcha_invalid_message}")
          end
          return ret
        else
          return valid_without_captcha?
        end
      end
      def valid_with_captcha?
        return valid_without_captcha? if RAILS_ENV == 'test'
        self.authenticate_with_captcha = true
        ret = self.valid?
        self.authenticate_with_captcha = false
        return ret
      end
      EOS
      return ret
    end
    
    def turing_save_method #:nodoc
      ret =<<-EOS
      def save_with_captcha
        self.authenticate_with_captcha = true
        ret = self.save_without_captcha
        self.authenticate_with_captcha = false
        return ret
      end
      def save(check_validations=true)
        self.authenticate_with_captcha = false
        self.save_without_captcha(check_validations)
      end
      EOS
      return ret
    end
    
  end
  
end

ActiveRecord::Base.module_eval do
  class << self; include SimpleCaptcha::ModelHelpers; end
end
