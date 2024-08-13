require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Fromthepage
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    config.action_dispatch.default_headers = {
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Request-Method' => "GET"
    }

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.neato = '/usr/bin/env neato'

    if config.respond_to?(:sass)
      require File.expand_path('../../lib/sassc_functions.rb', __FILE__)
    end

    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**/*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    config.i18n.available_locales = [:de, :en, :'en-GB', :es, :fr, :'fr-CA', :pt]
    config.i18n.fallbacks = true
    config.i18n.fallbacks = [:en]



  # load overrides for Thredded and other engines
  # config/application.rb
    overrides = "#{Rails.root}/app/overrides"
    Rails.autoloaders.main.ignore(overrides)

    config.to_prepare do
      Dir.glob("#{overrides}/**/*_override.rb").each do |override|
        load override
      end
    end

    # Load rake tasks
    Rails.application.load_tasks
  end


  #uncomment for development of SSO
  #Rails.application.config.action_controller.forgery_protection_origin_check=false
end
