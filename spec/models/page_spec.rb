require 'spec_helper'

describe Page do
  before(:each) do
    @page = FactoryGirl.create(:page)
  end

  subject { @page }

  it { should respond_to(:title) }

end
