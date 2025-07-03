Rails.application.config.to_prepare do
  ActiveStorage::DirectUploadsController.class_eval do
    skip_before_action :verify_authenticity_token, unless: -> { Rails.env.production? }
  end
end
