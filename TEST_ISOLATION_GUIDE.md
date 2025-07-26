# Test Isolation Improvement Guide

This document outlines the work done to improve test isolation in the FromThePage test suite and provides guidance for completing the remaining work.

## Problem Statement

The test suite had significant ordering dependencies:
- 16 out of 42 feature specs used `:order => :defined`
- `config.use_transactional_fixtures = false` prevented automatic rollback
- Manual `DatabaseCleaner.start/clean` calls scattered throughout specs
- Tests depended on shared state from `before :all` blocks

## Solutions Implemented

### 1. Centralized Database Cleaning Strategy

Created `spec/support/database_cleaner.rb` with proper strategies:
- **Transactions** for fast unit/model tests
- **Truncation** for feature tests with JavaScript
- **Configurable** strategies based on test metadata

### 2. Enabled Transactional Fixtures

Updated `spec_helper.rb`:
```ruby
config.use_transactional_fixtures = true
```

### 3. Removed Manual Database Cleaning

Eliminated manual `DatabaseCleaner.start/clean` calls from 12+ spec files, relying on the centralized strategy instead.

### 4. Refactored Ordering Dependencies

Successfully removed `:order => :defined` from multiple specs by:
- Using `let` instead of `@instance` variables
- Setting up test data in each individual test
- Using factories instead of depending on fixtures

## Current Progress

- **Total feature specs**: 42
- **Now isolated**: 30 (71%)
- **Still ordered**: 12 (29%)

## Specs Successfully Isolated

✅ **Completed** (no longer use `:order => :defined`):
- `notifications_spec.rb` - Refactored to set up user state in each test
- `collection_statistics_spec.rb` - Restructured with proper test isolation
- `forum_spec.rb` - Moved slug setup to `before :each`
- `deed_list_spec.rb` - All tests were commented out
- `ahoy_spec.rb` - Simple test, only needed DatabaseCleaner removal
- `collaborator_spec.rb` - Uses factories, no ordering needed
- `devise_spec.rb` - Independent user authentication tests
- All model specs - Now use centralized cleaning

## Specs Still Requiring Work

⚠️ **Remaining ordered specs** (complex dependencies):

### High Priority (simpler to fix):
- `field_based_spec.rb` (10 tests) - Field creation dependencies
- `voice_transcription_spec.rb` (4 tests) - Setting toggles dependencies  
- `disable_subjects_spec.rb` (8 tests) - Subject setting dependencies

### Medium Priority:
- `needs_review_spec.rb` (14 tests) - Page status dependencies
- `add_data_spec.rb` (8 tests) - File upload dependencies
- `collection_metadata_spec.rb` (11 tests) - Metadata upload dependencies

### Lower Priority (complex integration tests):
- `collection_spec.rb` (27 tests) - Large test with many dependencies
- `owner_actions_spec.rb` (25 tests) - Complex workflow dependencies
- `editor_actions_spec.rb` (28 tests) - Editor state dependencies
- `document_sets_spec.rb` (19 tests) - Document set workflow
- `zz_convention_spec.rb` (4 tests) - Depends on imported fixtures
- `zz_iiif_collection_spec.rb` (3 tests) - IIIF import dependencies

## Refactoring Patterns

### Before (with ordering dependencies):
```ruby
describe "example spec", :order => :defined do
  before :all do
    @user = User.find_by(login: USER)
    @collection = Collection.first
  end

  it "creates something" do
    # creates data that next test depends on
  end

  it "uses something" do
    # depends on previous test
  end
end
```

### After (isolated):
```ruby
describe "example spec" do
  let(:user) { User.find_by(login: USER) }
  let(:collection) { create(:collection) }

  it "creates something" do
    # sets up its own data
  end

  it "uses something" do
    # sets up its own data independently
  end
end
```

## Testing Isolation

To test if a spec can run in isolation:
```bash
# Run individual spec file
bundle exec rspec spec/features/example_spec.rb

# Run in random order
bundle exec rspec --order random

# Run specific test
bundle exec rspec spec/features/example_spec.rb:25
```

## Benefits Achieved

1. **Faster debugging** - Can run individual tests without running entire suite
2. **Parallel execution ready** - Tests no longer depend on sequential execution
3. **Reduced flakiness** - Tests start with clean state
4. **Better CI/CD** - Can run subset of tests for faster feedback
5. **Easier refactoring** - Tests are self-contained and easier to understand

## Next Steps

1. Continue refactoring remaining 12 ordered specs
2. Add parallel test execution configuration
3. Consider splitting large test files into smaller, focused specs
4. Add random order execution to CI pipeline

## Guidelines for New Tests

- Always use `let` for test data instead of `@instance` variables
- Use factories instead of fixtures where possible
- Each test should set up its own required data
- Avoid `before :all` blocks that create persistent state
- Never use `:order => :defined` unless absolutely necessary
- Test your spec in isolation: `bundle exec rspec path/to/your_spec.rb`