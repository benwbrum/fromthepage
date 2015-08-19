require 'rails_helper'

RSpec.describe "sc_collections/edit", :type => :view do
  before(:each) do
    @sc_collection = assign(:sc_collection, ScCollection.create!(
      :collection => nil,
      :context => "MyString"
    ))
  end

  it "renders the edit sc_collection form" do
    render

    assert_select "form[action=?][method=?]", sc_collection_path(@sc_collection), "post" do

      assert_select "input#sc_collection_collection_id[name=?]", "sc_collection[collection_id]"

      assert_select "input#sc_collection_context[name=?]", "sc_collection[context]"
    end
  end
end
