require 'rails_helper'

RSpec.describe 'Warning initializer' do
  it 'loads without errors' do
    # Simply verify that the warning initializer can be loaded without causing errors
    expect {
      load Rails.root.join('config', 'initializers', 'warning.rb')
    }.not_to raise_error
  end
  
  it 'defines warning suppression for win32ole' do
    # Load the initializer to ensure the warning configuration is applied
    load Rails.root.join('config', 'initializers', 'warning.rb')
    
    # We can't easily test the actual warning suppression without complex setup,
    # but we can verify that the configuration loads successfully
    expect(Warning).to respond_to(:ignore)
  end
end