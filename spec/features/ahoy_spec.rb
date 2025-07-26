require 'spec_helper'

describe 'Ahoy' do

  it 'logs a visit' do
    count = Visit.count
    visit root_path
    expect(Visit.count).to eq(count + 1)
  end
end