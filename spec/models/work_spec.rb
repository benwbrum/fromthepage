require 'spec_helper'

describe Work do

  before(:each) do
    @work = FactoryGirl.create(:work1) 
  end

  subject { @work }

  it { should respond_to(:title) }
  it { should respond_to(:description) }

  it "creates a work statistic" do
    expect{ FactoryGirl.create(:work1) }.to change{ WorkStatistic.count }.by(1)
  end

end
