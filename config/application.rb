require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Fromthepage
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.neato = '/usr/bin/env neato'
    config.encoding = 'utf-8'

    config.action_view.field_error_proc = Proc.new { |html_tag, instance|
      class_attr_index = html_tag.index 'class="'

      if class_attr_index
        html_tag.insert class_attr_index+7, 'invalid '
      else
        html_tag.insert html_tag.index('>'), ' class="invalid"'
      end
    }

    if config.respond_to?(:sass)
      require File.expand_path('../../lib/sass_functions.rb', __FILE__)
    end
  end
end
