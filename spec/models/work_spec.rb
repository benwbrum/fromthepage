require 'spec_helper'

describe Work do

  before(:each) do
    @work = FactoryGirl.create(:work1) 
  end

  subject { @work }

  it { should respond_to(:title) }
  it { should respond_to(:description) }

  it { should have_many(:pages).order(:position) }
  it { should belong_to(:owner).class_name(:User) }
  it { should belong_to(:collection) }
  it { should have_many(:deeds).order('created_at DESC') }
  it { should have_one(:ia_work) }
  it { should have_one(:work_statistic) }
  it { should have_and_belong_to_many(:scribes).class_name(:User) }
  
  it "creates a work statistic" do
    expect{ FactoryGirl.create(:work1) }.to change{ WorkStatistic.count }.by(1)
  end

end
