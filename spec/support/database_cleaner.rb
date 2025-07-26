RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do |example|
    # Use transactions for most tests (fast)
    DatabaseCleaner.strategy = :transaction
    
    # Use truncation for feature tests that use JavaScript
    # since they run in a separate thread and transactions don't work
    # Also use truncation for tests that are explicitly marked as needing it
    if example.metadata[:js] || 
       example.metadata[:type] == :feature ||
       example.metadata[:truncation]
      DatabaseCleaner.strategy = :truncation
    end
    
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  # For tests that need to share state across examples within a single test file,
  # you can use :shared_state metadata and handle cleanup manually
  config.before(:each, :shared_state) do
    DatabaseCleaner.strategy = :truncation
    # Don't start cleaner here - let the test manage state
  end

  config.after(:each, :shared_state) do
    # Don't clean here - let the test manage state  
  end
end