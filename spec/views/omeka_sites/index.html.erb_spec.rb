require 'spec_helper'

describe "omeka_sites/index" do
  before(:each) do
    assign(:omeka_sites, [
      stub_model(OmekaSite,
        :title => "Title",
        :api_url => "Api Url",
        :api_key => "Api Key",
        :user_id => ""
      ),
      stub_model(OmekaSite,
        :title => "Title",
        :api_url => "Api Url",
        :api_key => "Api Key",
        :user_id => ""
      )
    ])
  end

  it "renders a list of omeka_sites" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "Api Url".to_s, :count => 2
    assert_select "tr>td", :text => "Api Key".to_s, :count => 2
    assert_select "tr>td", :text => "".to_s, :count => 2
  end
end
