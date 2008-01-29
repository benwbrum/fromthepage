
require 'simple_captcha_config'
require 'simple_captcha_image'
require 'simple_captcha_action_view'
require 'simple_captcha_action_controller'
require 'simple_captcha_active_record'

class InitialConfig
  include SimpleCaptcha::ConfigTasks
end
InitialConfig.new.create_captcha_directories
