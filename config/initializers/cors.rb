if Settings.upload_host.present?
  logger = -> { Rails.logger }

  protocol = Rails.env.production? ? 'https' : 'http'

  # e.g. 'uploads.localhost' for dev
  # match to http://#{Settings.upload_host}:port
  host_parts = Settings.upload_host.split('.').map { |part| Regexp.escape(part) }
  domain = host_parts[-1]
  subdomain = host_parts[0]

  origin = [
    /\A#{protocol}:\/\/#{domain}:\d+\/?\z/,
    /\A#{protocol}:\/\/#{subdomain}\.#{domain}:\d+\/?\z/
  ]

  Rails.application.config.middleware.insert_before 0, Rack::Cors, logger: logger do
    allow do
      origins origin

      resource '*', headers: :any,
                    methods: [:get, :post, :put, :patch, :delete, :options, :head],
                    credentials: true
    end
  end
end
