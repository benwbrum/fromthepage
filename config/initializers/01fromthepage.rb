ADMIN_EMAILS = 'saracarl@gmail.com, benwbrum@gmail.com'
SENDING_EMAIL_ADDRESS = 'support@fromthepage.com'
SMTP_ENABLED = false
USE_PNG_LOGO = false
GUEST_DEED_COUNT = 3
GUEST_TRANSCRIPTION_ENABLED = false
FACEBOOK_PIXEL_ID = ''
MIXPANEL_ID = ''
GA_ACCOUNT = ''
CLARITY=''
#single sign on options below
ENABLE_GOOGLEOAUTH = false
GOOGLE_CLIENT_ID = ENV['GOOGLE_CLIENT_ID']
GOOGLE_CLIENT_SECRET = ENV['GOOGLE_CLIENT_SECRET']
ENABLE_SAML = true
#IDP_SSO_TARGET_URL = 'your.saml.url'
#IDP_SSO_TARGET_URL = 'https://capriza.github.io/samling/samling.html' #easy test for saml without a saml server
#the below isn't a reference to the cert file, but the actual cert.  See https://github.com/omniauth/omniauth-saml for other options, like fingerprint.
#the initializer/devise.rb file is where this is used, and if you want to use fingerprint rather than cert, you can modify that file
IDP_CERT = ENV['IDP_CERT'] 

# ReCAPTCHA Settings
RECAPTCHA_SITE_KEY = ENV['RECAPTCHA_SITE_KEY']
RECAPTCHA_SECRET_KEY = ENV['RECAPTCHA_SECRET_KEY']

BENTO_ENABLED = false
BENTO_ACCESS_TOKEN = ENV['BENTO_ACCESS_TOKEN']

# Nice Levels for Rake Import. See `nice_rake.rb`
NICE_RAKE_ENABLED = true
NICE_RAKE_LEVEL = 10 # Values values -20 to 19 (only root can set less than 0)

ENABLE_OPENAI = true
OPENAI_ACCESS_TOKEN=ENV['OPENAI_ACCESS_TOKEN']

ENABLE_TRANSKRIBUS=true
TRANSKRIBUS_ACCESS_TOKEN=ENV['TRANSKRIBUS_ACCESS_TOKEN']

# Elasticsearch settings
ELASTIC_ENABLED = ENV['ELASTIC_ENABLED']
ELASTIC_CLOUD_ID = ENV['ELASTIC_CLOUD_ID']
ELASTIC_API_KEY = ENV['ELASTIC_API_KEY']
ELASTIC_SUFFIX = ENV['ELASTIC_SUFFIX']
