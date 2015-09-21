require 'rails_helper'

RSpec.describe "document_uploads/edit", :type => :view do
  before(:each) do
    @document_upload = assign(:document_upload, DocumentUpload.create!(
      :user => nil,
      :collection => nil,
      :file => "MyString"
    ))
  end

  it "renders the edit document_upload form" do
    render

    assert_select "form[action=?][method=?]", document_upload_path(@document_upload), "post" do

      assert_select "input#document_upload_user_id[name=?]", "document_upload[user_id]"

      assert_select "input#document_upload_collection_id[name=?]", "document_upload[collection_id]"

      assert_select "input#document_upload_file[name=?]", "document_upload[file]"
    end
  end
end
