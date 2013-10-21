require 'spec_helper'

describe "omeka_sites/new" do
  before(:each) do
    assign(:omeka_site, stub_model(OmekaSite,
      :title => "MyString",
      :api_url => "MyString",
      :api_key => "MyString",
      :user_id => ""
    ).as_new_record)
  end

  it "renders new omeka_site form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => omeka_sites_path, :method => "post" do
      assert_select "input#omeka_site_title", :name => "omeka_site[title]"
      assert_select "input#omeka_site_api_url", :name => "omeka_site[api_url]"
      assert_select "input#omeka_site_api_key", :name => "omeka_site[api_key]"
      assert_select "input#omeka_site_user_id", :name => "omeka_site[user_id]"
    end
  end
end
