require 'spec_helper'

describe Deed do

  before(:each) do
    @deed = FactoryGirl.create(:deed1)
  end

  # subject { @article }

  it { should belong_to(:article) } 
  it { should belong_to(:collection) }
  it { should belong_to(:note) }
  it { should belong_to(:page) }
  it { should belong_to(:user) } 
  it { should belong_to(:work) }

end
