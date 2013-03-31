require 'spec_helper'

describe PageVersion do

  before(:each) do
    @page_version = FactoryGirl.create(:page_version1)
  end

  it { should belong_to(:page) }
  it { should belong_to(:user) }
end
