require 'spec_helper'

describe "omeka_items/index" do
  before(:each) do
    assign(:omeka_items, [
      stub_model(OmekaItem,
        :title => "Title",
        :subject => "Subject",
        :description => "Description",
        :rights => "Rights",
        :creator => "Creator",
        :format => "Format",
        :coverage => "Coverage",
        :omeka_site_id => 1,
        :omeka_id => 2,
        :omeka_url => "Omeka Url",
        :omeka_collection_id => 3,
        :user_id => 4
      ),
      stub_model(OmekaItem,
        :title => "Title",
        :subject => "Subject",
        :description => "Description",
        :rights => "Rights",
        :creator => "Creator",
        :format => "Format",
        :coverage => "Coverage",
        :omeka_site_id => 1,
        :omeka_id => 2,
        :omeka_url => "Omeka Url",
        :omeka_collection_id => 3,
        :user_id => 4
      )
    ])
  end

  it "renders a list of omeka_items" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Title".to_s, :count => 2
    assert_select "tr>td", :text => "Subject".to_s, :count => 2
    assert_select "tr>td", :text => "Description".to_s, :count => 2
    assert_select "tr>td", :text => "Rights".to_s, :count => 2
    assert_select "tr>td", :text => "Creator".to_s, :count => 2
    assert_select "tr>td", :text => "Format".to_s, :count => 2
    assert_select "tr>td", :text => "Coverage".to_s, :count => 2
    assert_select "tr>td", :text => 1.to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "Omeka Url".to_s, :count => 2
    assert_select "tr>td", :text => 3.to_s, :count => 2
    assert_select "tr>td", :text => 4.to_s, :count => 2
  end
end
