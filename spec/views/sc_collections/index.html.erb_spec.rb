require 'rails_helper'

RSpec.describe "sc_collections/index", :type => :view do
  before(:each) do
    assign(:sc_collections, [
      ScCollection.create!(
        :collection => nil,
        :context => "Context"
      ),
      ScCollection.create!(
        :collection => nil,
        :context => "Context"
      )
    ])
  end

  it "renders a list of sc_collections" do
    render
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => "Context".to_s, :count => 2
  end
end
