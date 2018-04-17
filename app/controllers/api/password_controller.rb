class Api::PasswordController < Api::ApiController
  
  def public_actions
    return [:create,:confirm]
  end
 
  def create
    @user = User.find_by(email: params[:email].downcase)
    if @user
      @user.created_at_was
      @user.send_reset_password_instructions
      render_serialized ResponseWS.simple_ok('api.reset_password.success')
    else
      render_serialized ResponseWS.simple_error('api.reset_password.fail')
    end
  end


  def confirm
    user = User.reset_password_by_token(params);
    if user.errors.empty?
      render_serialized ResponseWS.ok('api.reset_password.confirm.success', user)
    else
      render_serialized ResponseWS.simple_error(user.errors.full_messages.to_sentence)
    end
  end
  
end
