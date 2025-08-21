require 'capybara/rspec'
require 'selenium/webdriver'

if ENV['CI'] == 'true'
  Capybara.register_driver :chromium do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.binary = '/usr/bin/chromium'
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")

    Capybara::Selenium::Driver.new(
      app,
      browser: :chrome,
      options: options
    )
  end

  Capybara.javascript_driver = :chromium
end

Capybara.configure do |config|
  config.asset_host = 'http://localhost:3000'
  config.raise_server_errors = false
end
