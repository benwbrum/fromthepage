require 'rails_helper'

RSpec.describe "external_api_requests/new", type: :view do
  before(:each) do
    assign(:external_api_request, ExternalApiRequest.new(
      user: nil,
      collection: nil,
      work: nil,
      page: nil,
      engine: "MyString",
      status: "MyString",
      params: "MyText"
    ))
  end

  it "renders new external_api_request form" do
    render

    assert_select "form[action=?][method=?]", external_api_requests_path, "post" do

      assert_select "input[name=?]", "external_api_request[user_id]"

      assert_select "input[name=?]", "external_api_request[collection_id]"

      assert_select "input[name=?]", "external_api_request[work_id]"

      assert_select "input[name=?]", "external_api_request[page_id]"

      assert_select "input[name=?]", "external_api_request[engine]"

      assert_select "input[name=?]", "external_api_request[status]"

      assert_select "textarea[name=?]", "external_api_request[params]"
    end
  end
end
