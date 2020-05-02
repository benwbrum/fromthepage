Rails.application.middleware.use Oink::Middleware
Rails.application.middleware.use( Oink::Middleware, :logger => Rails.logger )
