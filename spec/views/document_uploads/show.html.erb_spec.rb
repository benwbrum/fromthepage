require 'rails_helper'

RSpec.describe "document_uploads/show", :type => :view do
  before(:each) do
    @document_upload = assign(:document_upload, DocumentUpload.create!(
      :user => nil,
      :collection => nil,
      :file => "File"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/File/)
  end
end
