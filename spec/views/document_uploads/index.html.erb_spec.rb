require 'rails_helper'

RSpec.describe "document_uploads/index", :type => :view do
  before(:each) do
    assign(:document_uploads, [
      DocumentUpload.create!(
        :user => nil,
        :collection => nil,
        :file => "File"
      ),
      DocumentUpload.create!(
        :user => nil,
        :collection => nil,
        :file => "File"
      )
    ])
  end

  it "renders a list of document_uploads" do
    render
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => nil.to_s, :count => 2
    assert_select "tr>td", :text => "File".to_s, :count => 2
  end
end
