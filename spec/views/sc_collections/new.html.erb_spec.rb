require 'rails_helper'

RSpec.describe "sc_collections/new", :type => :view do
  before(:each) do
    assign(:sc_collection, ScCollection.new(
      :collection => nil,
      :context => "MyString"
    ))
  end

  it "renders new sc_collection form" do
    render

    assert_select "form[action=?][method=?]", sc_collections_path, "post" do

      assert_select "input#sc_collection_collection_id[name=?]", "sc_collection[collection_id]"

      assert_select "input#sc_collection_context[name=?]", "sc_collection[context]"
    end
  end
end
