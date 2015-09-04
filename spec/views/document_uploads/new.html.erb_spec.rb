require 'rails_helper'

RSpec.describe "document_uploads/new", :type => :view do
  before(:each) do
    assign(:document_upload, DocumentUpload.new(
      :user => nil,
      :collection => nil,
      :file => "MyString"
    ))
  end

  it "renders new document_upload form" do
    render

    assert_select "form[action=?][method=?]", document_uploads_path, "post" do

      assert_select "input#document_upload_user_id[name=?]", "document_upload[user_id]"

      assert_select "input#document_upload_collection_id[name=?]", "document_upload[collection_id]"

      assert_select "input#document_upload_file[name=?]", "document_upload[file]"
    end
  end
end
