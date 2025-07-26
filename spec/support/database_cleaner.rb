RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    # Use transactions for most tests (fast)
    DatabaseCleaner.strategy = :transaction
    
    # Use truncation for feature tests that use JavaScript
    # since they run in a separate thread and transactions don't work
    if example.metadata[:js] || example.metadata[:type] == :feature
      DatabaseCleaner.strategy = :truncation
    end
    
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end