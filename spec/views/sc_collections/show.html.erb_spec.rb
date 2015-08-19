require 'rails_helper'

RSpec.describe "sc_collections/show", :type => :view do
  before(:each) do
    @sc_collection = assign(:sc_collection, ScCollection.create!(
      :collection => nil,
      :context => "Context"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/Context/)
  end
end
