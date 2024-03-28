# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'factory_bot'
require 'webmock/rspec'
require 'database_cleaner'
require 'coveralls'
Coveralls.wear!

DatabaseCleaner.strategy = :transaction

WebMock.allow_net_connect!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
#ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before(:suite) do
    %x[bundle exec rake assets:precompile]

    puts "Setting Collection Work Counts..."
    Collection.all.each do |c|
      Collection.reset_counters c.id, :works
    end

    puts "Setting DocumentSet Work Counts..."
    DocumentSet.all.each do |ds|
      DocumentSet.reset_counters ds.id, :document_set_works
    end
  end

  config.include FactoryBot::Syntax::Methods

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  #  config.order = "random"

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explictly tag your specs with their type, e.g.:
  #
  #     describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/v/3-0/docs
  config.infer_spec_type_from_file_location!

  config.include Capybara::DSL

  config.include Warden::Test::Helpers
end

Capybara.configure do |config|
  config.asset_host = "http://localhost:3000"
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
    fill_in('page_source_text', :with => text)
  elsif page.has_field?('page_source_translation') # we find page_source_translation
    fill_in('page_source_translation', :with => text)
  else #codemirror
    script = "myCodeMirror.setValue(#{text.to_json});"
    page.execute_script(script)
  end
end

