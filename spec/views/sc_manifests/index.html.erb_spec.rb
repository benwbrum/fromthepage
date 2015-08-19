require 'rails_helper'

RSpec.describe "sc_manifests/index", :type => :view do
  before(:each) do
    assign(:sc_manifests, [
      ScManifest.create!(
        :work => nil,
        :sc_collection => nil,
        :sc_id => "Sc",
        :label => "Label",
        :metadata => "MyText",
        :first_sequence_id => "First Sequence",
        :first_sequence_label => "First Sequence Label"
      ),
      ScManifest.create!(
        :work => nil,
        :sc_collection => nil,
        :sc_id => "Sc",
        :label => "Label",
        :metadata => "MyText",
        :first_sequence_id => "First Sequence",
        :first_sequence_label => "First Sequence Label"
      )
    ])
  end

  it "renders a list of sc_manifests" do
    render
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => "Sc".to_s, :count => 2
    assert_select "tr>td", :text => "Label".to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
    assert_select "tr>td", :text => "First Sequence".to_s, :count => 2
    assert_select "tr>td", :text => "First Sequence Label".to_s, :count => 2
  end
end
