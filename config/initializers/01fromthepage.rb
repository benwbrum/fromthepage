ADMIN_EMAILS = 'saracarl@gmail.com, benwbrum@gmail.com'
SENDING_EMAIL_ADDRESS = 'support@fromthepage.com'
SMTP_ENABLED = false
USE_PNG_LOGO = false
GUEST_DEED_COUNT = 3
FACEBOOK_PIXEL_ID = ''
MIXPANEL_ID = ''
GA_ACCOUNT = ''
#single sign on options below
ENABLE_GOOGLEOAUTH = false
GOOGLE_CLIENT_ID = ENV['GOOGLE_CLIENT_ID']
GOOGLE_CLIENT_SECRET = ENV['GOOGLE_CLIENT_SECRET']
ENABLE_SAML = false
IDP_SSO_TARGET_URL = 'your.saml.url'
#IDP_SSO_TARGET_URL = 'https://capriza.github.io/samling/samling.html' #easy test for saml without a saml server
#the below isn't a reference to the cert file, but the actual cert.  See https://github.com/omniauth/omniauth-saml for other options, like fingerprint.
#the initializer/devise.rb file is where this is used, and if you want to use fingerprint rather than cert, you can modify that file
IDP_CERT = ENV['IDP_CERT'] 
