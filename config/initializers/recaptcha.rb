Recaptcha.configure do |config|
  config.public_key  = ENV['PUBLIC_RECAPTCHA_KEY']
  config.private_key = ENV['PRIVATE_RECAPTCHA_KEY']
  config.proxy = 'http://myproxy.com.au:8080'
end


