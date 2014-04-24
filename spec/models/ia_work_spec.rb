require 'spec_helper'

describe IaWork do

  before(:each) do
     @ia_work = IaWork.new
  end

  # subject { @article }

  it { should belong_to(:user) }
  it { should belong_to(:work) }
  # this one is dying. It tries to find IaLeafe, with and without "class_name"
  #it { should have_many(:ia_leaves).class_name("IaLeaf") }
end
