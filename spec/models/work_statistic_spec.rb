require 'spec_helper'

describe WorkStatistic do

  before(:each) do
    @work = FactoryGirl.create(:work1)
    @work_statistic = FactoryGirl.create(:work_statistic1)
  end

  subject { @work_statistic }

  it { should belong_to(:work) }

  it "creates a work statistic" do
    expect{ FactoryGirl.create(:work1) }.to change{ WorkStatistic.count }.by(1)
  end

end
