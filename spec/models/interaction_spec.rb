require 'spec_helper'

describe Interaction do

  before(:each) do
    @interaction = FactoryGirl.create(:interaction1)
  end

  # subject { @article }

  it { should belong_to(:collection) }
  it { should belong_to(:work) }
  it { should belong_to(:page) }
  it { should belong_to(:user) }

end
