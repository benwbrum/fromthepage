require 'spec_helper'

describe IaLeaf do

  before(:each) do
    leaf = IaLeaf.new
  end

  # subject { @article }

  it { should belong_to(:ia_work) }
  it { should belong_to(:page) }

end
