Devise::TokenAuthenticatable.setup do |config|
  
  # enable reset of the authentication token before the model is saved,
  # defaults to false
  config.should_reset_authentication_token = false

  # enables the setting of the authentication token - if not already - before the model is saved,
  # defaults to false
  config.should_ensure_authentication_token = true
end
