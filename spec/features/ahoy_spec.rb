require 'spec_helper'

describe 'Ahoy' do
  before :each do
    DatabaseCleaner.start
  end
  after :each do
    DatabaseCleaner.clean
  end

  it 'logs a visit' do
    visit count = Visit.count
    visit root_path
    expect(Visit.count).to eq(count + 1)
  end
end