# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_fromthepage235_session',
  :secret      => 'd7af54fc69f57a54e356d87cc7dba0c38749cef3cdd11d3d79d424dba9c3e88cebe788afa7a2c31d88aebff1abab09849fa858cdbd10d5531ef1fd166be38887'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
