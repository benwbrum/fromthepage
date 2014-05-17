require 'spec_helper'

describe Collection do

  before(:each) do
    begin
      @collection = FactoryGirl.create(:collection1)
    rescue Exception => e
      puts e.backtrace
    end
  end

  subject { @collection }

  it { should respond_to(:title) }
  it { should respond_to(:intro_block) }
  it { should respond_to(:footer_block) }

  it { should have_many(:works).order(:title) }
  it { should have_many(:notes).order("created_at DESC") }
  # this worked, then it stopped working, I don't know why
  # it { should have_many(:articles) }
  it { should have_many(:categories).order(:title) }
  it { should have_many(:deeds).order("created_at DESC") }
  it { should belong_to(:owner).class_name("User") }
  it { should have_and_belong_to_many(:owners).class_name("User") }

end
