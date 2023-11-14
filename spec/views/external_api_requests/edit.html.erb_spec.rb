require 'rails_helper'

RSpec.describe "external_api_requests/edit", type: :view do
  before(:each) do
    @external_api_request = assign(:external_api_request, ExternalApiRequest.create!(
      user: nil,
      collection: nil,
      work: nil,
      page: nil,
      engine: "MyString",
      status: "MyString",
      params: "MyText"
    ))
  end

  it "renders the edit external_api_request form" do
    render

    assert_select "form[action=?][method=?]", external_api_request_path(@external_api_request), "post" do

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
