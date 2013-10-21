require 'spec_helper'

describe "omeka_sites/show" do
  before(:each) do
    @omeka_site = assign(:omeka_site, stub_model(OmekaSite,
      :title => "Title",
      :api_url => "Api Url",
      :api_key => "Api Key",
      :user_id => ""
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Title/)
    rendered.should match(/Api Url/)
    rendered.should match(/Api Key/)
    rendered.should match(//)
  end
end
