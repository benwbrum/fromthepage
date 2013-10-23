require 'spec_helper'

describe "omeka_items/show" do
  before(:each) do
    @omeka_item = assign(:omeka_item, stub_model(OmekaItem,
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
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Title/)
    rendered.should match(/Subject/)
    rendered.should match(/Description/)
    rendered.should match(/Rights/)
    rendered.should match(/Creator/)
    rendered.should match(/Format/)
    rendered.should match(/Coverage/)
    rendered.should match(/1/)
    rendered.should match(/2/)
    rendered.should match(/Omeka Url/)
    rendered.should match(/3/)
    rendered.should match(/4/)
  end
end
