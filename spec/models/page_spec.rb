require 'spec_helper'

describe Page do
  before(:each) do
    # WorkController.class.skip_before_filter :authorized?
    @page = FactoryGirl.create(:page)
  end

  subject { @page }

  it { should respond_to(:title) }

end
