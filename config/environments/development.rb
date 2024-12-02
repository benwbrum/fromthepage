Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  Rails.application.routes.default_url_options = config.action_mailer.default_url_options =  { host: 'localhost:3000' }

  config.action_mailer.delivery_method = :postmark

  config.action_mailer.postmark_settings = {
    api_token: ''
  }


  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  Rails.application.routes.default_url_options[:host] = 'localhost:3000'

  # Allow codespaces host
  unless ENV["CODESPACE_NAME"].nil?
    config.hosts << ENV["CODESPACE_NAME"]+"-3000.app.github.dev"
  end

  # location of system calls on this machine
  NEATO = '/usr/bin/neato'
  RAKE = '/usr/bin/env rake'
  TEX_PATH='/usr/local/texlive/2017/bin/x86_64-linux/'
  UPGRADE_FORM_LINK='https://app.bentonow.com/f/6247d0278bfbafc3ef75b753f26a46d2/red-tree-885/'

  config.pontiiif_server = 'http://pontiiif.brumfieldlabs.com/'

  ## Config for MailCatcher ##
  # Install mailcatcher locally on your machine 'gem install mailcatcher'
  # Run 'mailcatcher' in the terminal to start the server
  # Open 'http://localhost:1080/' in your browser to see mail sent

  Ahoy.geocode = false
end
