require 'spec_helper'

describe "omeka_sites/edit" do
  before(:each) do
    @omeka_site = assign(:omeka_site, stub_model(OmekaSite,
      :title => "MyString",
      :api_url => "MyString",
      :api_key => "MyString",
      :user_id => ""
    ))
  end

  it "renders the edit omeka_site form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => omeka_sites_path(@omeka_site), :method => "post" do
      assert_select "input#omeka_site_title", :name => "omeka_site[title]"
      assert_select "input#omeka_site_api_url", :name => "omeka_site[api_url]"
      assert_select "input#omeka_site_api_key", :name => "omeka_site[api_key]"
      assert_select "input#omeka_site_user_id", :name => "omeka_site[user_id]"
    end
  end
end
