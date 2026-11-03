# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password, :authenticity_token, :source_text, :source_translation, :fields,
  :save_recovery_token, :recovery_id]
