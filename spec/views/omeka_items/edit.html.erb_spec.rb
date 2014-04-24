require 'spec_helper'

describe "omeka_items/edit" do
  before(:each) do
    @omeka_item = assign(:omeka_item, stub_model(OmekaItem,
      :title => "MyString",
      :subject => "MyString",
      :description => "MyString",
      :rights => "MyString",
      :creator => "MyString",
      :format => "MyString",
      :coverage => "MyString",
      :omeka_site_id => 1,
      :omeka_id => 1,
      :omeka_url => "MyString",
      :omeka_collection_id => 1,
      :user_id => 1
    ))
  end

  it "renders the edit omeka_item form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => omeka_items_path(@omeka_item), :method => "post" do
      assert_select "input#omeka_item_title", :name => "omeka_item[title]"
      assert_select "input#omeka_item_subject", :name => "omeka_item[subject]"
      assert_select "input#omeka_item_description", :name => "omeka_item[description]"
      assert_select "input#omeka_item_rights", :name => "omeka_item[rights]"
      assert_select "input#omeka_item_creator", :name => "omeka_item[creator]"
      assert_select "input#omeka_item_format", :name => "omeka_item[format]"
      assert_select "input#omeka_item_coverage", :name => "omeka_item[coverage]"
      assert_select "input#omeka_item_omeka_site_id", :name => "omeka_item[omeka_site_id]"
      assert_select "input#omeka_item_omeka_id", :name => "omeka_item[omeka_id]"
      assert_select "input#omeka_item_omeka_url", :name => "omeka_item[omeka_url]"
      assert_select "input#omeka_item_omeka_collection_id", :name => "omeka_item[omeka_collection_id]"
      assert_select "input#omeka_item_user_id", :name => "omeka_item[user_id]"
    end
  end
end
