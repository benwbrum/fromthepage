class Api::LoginController < Api::ApiController

  def public_actions
    return [:login]
  end

  def login
    username = params[:username]
    password = params[:password]
    user = User.find_for_authentication(:login => username)
    user.valid_password?(password) ? user : nil
    render_serialized(user)
  end

end
