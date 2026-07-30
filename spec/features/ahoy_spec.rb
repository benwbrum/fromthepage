require 'spec_helper'

RSpec.describe 'Ahoy' do
  before do
    DatabaseCleaner.start
    Capybara.reset_sessions!
  end

  after do
    Capybara.reset_sessions!
    DatabaseCleaner.clean
  end

  it 'logs a visit' do
    expect { visit root_path }.to change(Visit, :count).by(1)
  end
end
