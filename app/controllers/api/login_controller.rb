class Api::LoginController < Api::ApiController

  def public_actions
    return [:login]
  end

  def login
    username = params[:username]
    password = params[:password]
    user = User.find_for_authentication(["login = :value OR lower(email) = lower(:value)", { :value => username}])
    if (user != nil && user.valid_password?(password))
      # Record login event
      alert = GamificationHelper.loginEvent(user.email)
      render_serialized ResponseWS.ok('api.login.success',user,alert)
    else
      render_serialized ResponseWS.simple_error('api.login.fail')
    end
  end

end
