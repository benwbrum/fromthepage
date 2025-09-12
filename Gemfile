# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.3.5'

gem 'rails', '~> 7.2.1'
gem 'puma'
gem 'bootsnap', require: false

# Core / Models / Business logic
gem 'mysql2'
gem 'activerecord-import', '~> 2.1'
gem 'acts_as_list'
gem 'acts_as_tree'
gem 'interactor-rails', '~> 2.0'
gem 'friendly_id'
gem 'thredded', '~> 1.1'

# Authentication / Security
gem 'devise'
gem 'devise-encryptable'
gem 'devise_masquerade', '~> 1.2.0'
gem 'omniauth', '~> 1.9'
gem 'omniauth-google-oauth2'
gem 'omniauth-multi-provider', '~> 0.2.1'
gem 'omniauth-saml', '~> 1.10.6'
gem 'rack-attack'
gem 'recaptcha', require: 'recaptcha/rails'

# File handling / Media
gem 'carrierwave'
gem 'rmagick'
gem 'rubyzip'

# HTTP / API / External SDKs
gem 'httparty'
gem 'savon', '~> 2.15', '>= 2.15.1'
gem 'ruby-openai'
gem 'open3'
gem 'bento-sdk', github: 'bentonow/bento-ruby-sdk', branch: 'master'
gem 'iiif-image-api', git: 'https://github.com/samvera-labs/iiif-image-api.git', branch: 'main'
gem 'iiif-presentation'
gem 'riiif'

# Data / Parsing / Search
gem 'nokogiri'
gem 'roo'
gem 'charlock_holmes'
gem 'nkf'
gem 'net-pop', github: 'ruby/net-pop'
gem 'forty_facets'
gem 'chewy'

# Analytics / Background / Metrics
gem 'ahoy_matey'
gem 'newrelic_rpm'
gem 'rack-mini-profiler'
gem 'flamegraph'
gem 'memory_profiler'
gem 'meta_request'
gem 'stackprof'


# Internationalization / Localization
gem 'rails-i18n', '~> 7.0.0'
gem 'http_accept_language'
gem 'iso-639'
gem 'rtl'

# Email / Notifications
gem 'postmark-rails'
gem 'mail', '~> 2.7'
gem 'gravatar_image_tag', github: 'Tinix/gravatar_image_tag'

# Frontend / UI
gem 'importmap-rails'
gem 'stimulus-rails'
gem 'turbo-rails'
gem 'jquery-rails'
gem 'jquery-ui-sass-rails'
gem 'slim'
gem 'sassc-rails'
gem 'autoprefixer-rails'
gem 'active_link_to'
gem 'clipboard-rails'
gem 'ajax-datatables-rails', '~> 1.0.0'
gem 'will_paginate'

# Utilities / Helpers
gem 'text'
gem 'diffy'
gem 'edtf'
gem 'edtf-humanize'
gem 'warning'
gem 'config'
gem 'rack-reverse-proxy', require: 'rack/reverse_proxy'
gem 'browser', '~> 2.0'
gem 'user_agent_parser'

group :development do
  gem 'capistrano', '~> 3.10', require: false
  gem 'capistrano-bundler', '~> 1.6'
  gem 'capistrano-rails', '~> 1.4', require: false
  gem 'html-pipeline', '~> 2.14'
  gem 'rvm1-capistrano3', require: false
end

group :assets do
  gem 'uglifier'
  gem 'terser'
end

group :development, :test do
  gem 'dotenv-rails'
  gem 'dotenv', require: 'dotenv/load'
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'annotaterb'
  gem 'rubocop-rails-omakase', require: false

  # Debugging / dev tools
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'bullet'
  gem 'i18n-tasks'
  gem 'launchy'
  gem 'listen'
  gem 'pry'
  gem 'pry-awesome_print'
  gem 'pry-byebug'
  gem 'easy_translate'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'rails-controller-testing'
  gem 'selenium-webdriver'
  gem 'shoulda'
  gem 'simplecov',      require: false
  gem 'simplecov-lcov', require: false
  gem 'vcr'
  gem 'webmock', require: false
  gem 'with_model'
end
