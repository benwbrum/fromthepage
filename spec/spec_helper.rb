ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
require 'factory_bot'
require 'webmock/rspec'
require 'database_cleaner'

require 'coveralls'
Coveralls.wear!('rails')

DatabaseCleaner.strategy = :transaction

WebMock.allow_net_connect!

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = false

  config.before(:suite) do
    `bundle exec rake assets:precompile`

    puts 'Setting Collection Work Counts...'
    Collection.all.each do |c|
      Collection.reset_counters c.id, :works
    end

    puts 'Setting DocumentSet Work Counts...'
    DocumentSet.all.each do |ds|
      DocumentSet.reset_counters ds.id, :document_set_works
    end
  end

  config.include FactoryBot::Syntax::Methods

  config.infer_spec_type_from_file_location!

  config.include Capybara::DSL

  config.include Warden::Test::Helpers

  config.add_formatter 'Fuubar'
end

Capybara.configure do |config|
  config.asset_host = 'http://localhost:3000'
  config.raise_server_errors = false
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

INACTIVE = "ron"
REST_USER = "george"
USER = "eleanor"
OWNER = "margaret"
NEW_OWNER = "harry"
ADMIN = "julia"

# Set this for mailer tests
silence_warnings do
  SMTP_ENABLED = true
end
ActionMailer::Base.perform_deliveries = true

def wait_for_upload_processing
  while DocumentUpload.where.not(:status => 'finished').count > 0
    sleep 2
  end
end

def fill_in_editor_field(text)
  if page.has_field?('page_source_text') # we find page_source_text
    fill_in('page_source_text', with: text)
  elsif page.has_field?('page_source_translation') # we find page_source_translation
    fill_in('page_source_translation', with: text)
  else # codemirror
    script = "myCodeMirror.setValue(#{text.to_json});"
    page.execute_script(script)
  end
end
