# Set constants to nil if they aren't defined already so
# the app doesn't blow up when it's updtaed
RECAPTCHA_SITE_KEY = nil unless defined?(RECAPTCHA_SITE_KEY)
RECAPTCHA_SECRET_KEY = nil unless defined?(RECAPTCHA_SITE_KEY)

# Conditionally set RECAPTCHA_ENABLED based on whether ReCAPTCHA configs
# are set. Can be overridden by setting the RECAPTCHA_ENABLED flag explicitly.
if defined?(RECAPTCHA_ENABLED) == nil
  if RECAPTCHA_SITE_KEY && RECAPTCHA_SECRET_KEY
    RECAPTCHA_ENABLED = true
  else
    RECAPTCHA_ENABLED = false
  end
end

# Only config if the variables are not nil
if RECAPTCHA_SITE_KEY && RECAPTCHA_SECRET_KEY
  Recaptcha.configure do |config|
    config.site_key  = RECAPTCHA_SITE_KEY
    config.secret_key = RECAPTCHA_SECRET_KEY
    # Uncomment the following line if you are using a proxy server:
    # config.proxy = 'http://myproxy.com.au:8080'
  end
end
