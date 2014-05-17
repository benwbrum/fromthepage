require 'spec_helper'

describe Note do

  before(:each) do
    @note = FactoryGirl.create(:note1)
  end

  # subject { @article }

  it { should belong_to(:user) }
  it { should belong_to(:page) }
  it { should belong_to(:work) }
  it { should belong_to(:collection) }

  it { should have_one(:deed) }

end
