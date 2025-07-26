require 'spec_helper'

# Test that our database cleaning strategy is working correctly
describe "Database isolation test", type: :feature do
  
  it "should clean data between tests - test 1" do
    # Create some test data
    user = create(:user, login: 'test_user_1')
    collection = create(:collection, title: 'Test Collection 1')
    
    expect(User.where(login: 'test_user_1').count).to eq(1)
    expect(Collection.where(title: 'Test Collection 1').count).to eq(1)
  end
  
  it "should clean data between tests - test 2" do
    # This should start with a clean slate
    expect(User.where(login: 'test_user_1').count).to eq(0)
    expect(Collection.where(title: 'Test Collection 1').count).to eq(0)
    
    # Create different test data
    user = create(:user, login: 'test_user_2')
    collection = create(:collection, title: 'Test Collection 2')
    
    expect(User.where(login: 'test_user_2').count).to eq(1)
    expect(Collection.where(title: 'Test Collection 2').count).to eq(1)
  end
  
  it "should clean data between tests - test 3", :js => true do
    # This should also start with a clean slate (testing JS test cleaning)
    expect(User.where(login: 'test_user_1').count).to eq(0)
    expect(User.where(login: 'test_user_2').count).to eq(0)
    expect(Collection.where(title: 'Test Collection 1').count).to eq(0)
    expect(Collection.where(title: 'Test Collection 2').count).to eq(0)
    
    # Create test data for JS test
    user = create(:user, login: 'test_user_js')
    collection = create(:collection, title: 'Test Collection JS')
    
    expect(User.where(login: 'test_user_js').count).to eq(1)
    expect(Collection.where(title: 'Test Collection JS').count).to eq(1)
  end
end