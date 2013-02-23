require 'spec_helper'

describe WorkStatistic do

  before(:each) do
    @work = FactoryGirl.create(:work) 
  end

  subject { @work_statistic }


  it "creates a work statistic" do
    expect{ FactoryGirl.create(:work) }.to change{ WorkStatistic.count }.by(1)
  end

  it "does stuff" do
    work_stat = @work.work_statistic
    puts "work_stat.inspect: #{work_stat.inspect}"
  end

end
