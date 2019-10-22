source 'https://rubygems.org'

gem 'rails', '4.1.2'


gem 'will_paginate'
#gem 'rmagick', '2.13.2', require: "RMagick"
gem 'rmagick'
gem 'nokogiri'
gem 'oai', git: 'https://github.com/mispy/ruby-oai.git'
gem 'capistrano', '~> 3.4.0'
gem 'capistrano-rails', '= 1.1.3'
gem 'capistrano-bundler', '~> 1.1.2'
gem 'rvm1-capistrano3', require: false
gem 'jquery-rails'
gem 'savon', '~> 2.12.0'
gem 'mysql2','0.3.21'

gem "recaptcha", require: "recaptcha/rails"

gem 'omeka_client', git: 'https://github.com/benwbrum/omeka_client'

gem 'acts_as_list'
gem 'acts_as_tree'

gem 'devise', '3.4.1'
gem 'devise-encryptable'

gem 'protected_attributes'
gem 'carrierwave'
gem 'rubyzip'
gem 'render_anywhere'

gem 'ahoy_matey'
gem 'pry'
gem 'oink'

gem 'riiif'
gem 'iiif-presentation', git: 'https://github.com/benwbrum/osullivan', branch: 'service_is_array'

gem 'omniauth-saml'
gem 'omniauth-google-oauth2'

gem 'rack-reverse-proxy', :require => 'rack/reverse_proxy'


group :assets do
  gem 'therubyracer'
  gem 'uglifier'
end

group :test do
  gem 'database_cleaner'
  gem 'capybara'
  gem 'shoulda'
  gem 'webmock', require: false
  gem 'vcr'
  gem 'coveralls', require: false
end

group :development, :test do
  gem 'rspec-rails'
  gem 'launchy'
  gem 'capybara-webkit'
  gem 'pry-byebug'
  gem 'factory_bot_rails'
  gem 'pry-awesome_print' # makes console output easy to read
  gem 'better_errors' # creates console in browser for errors
  gem 'binding_of_caller' # goes with better_errors
  # Supporting gem for RailsPanel
  # https://github.com/dejan/rails_panel
  gem 'bullet'
end

# Use SASS for stylesheets
gem 'sassc-rails'

# Use Autoprefixer for vendor prefixes
gem 'autoprefixer-rails', '<= 8.6.5'

# Use Slim for templates
gem 'slim', '~> 3.0.0'

# Gravatar Image Tag
gem 'gravatar_image_tag'

#Admin masquerade as a user
gem 'devise_masquerade'

#friendly routes
gem 'friendly_id'

#support right to left languages
gem 'rtl'
gem 'iso-639'

# Quiet asset lines in log files
gem 'quiet_assets', '~> 1.1.0', group: :development

# Profiling for use in prod
gem 'flamegraph'
gem 'memory_profiler'
gem 'meta_request'
gem 'rack-mini-profiler'
gem 'stackprof'
