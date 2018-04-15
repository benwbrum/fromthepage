require 'gamification_helper'
class Api::PasswordController < Api::ApiController
 
  def create
    #puts "create!!!!"
   #puts User.reset_password_keys("new_password", "new_password") 
    @user = User.find_by(email: params[:user][:email].downcase)
    if @user
      @user.created_at_was
      @user.send_reset_password_instructions
      #hay que crear los textos de response para password , lepuse ese paraque devoviera algo mientras peleaba con device
      render_serialized ResponseWS.simple_error('api.login.fail')
    end
  end

end
