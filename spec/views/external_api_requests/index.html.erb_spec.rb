require 'rails_helper'

RSpec.describe "external_api_requests/index", type: :view do
  before(:each) do
    assign(:external_api_requests, [
      ExternalApiRequest.create!(
        user: nil,
        collection: nil,
        work: nil,
        page: nil,
        engine: "Engine",
        status: "Status",
        params: "MyText"
      ),
      ExternalApiRequest.create!(
        user: nil,
        collection: nil,
        work: nil,
        page: nil,
        engine: "Engine",
        status: "Status",
        params: "MyText"
      )
    ])
  end

  it "renders a list of external_api_requests" do
    render
    assert_select "tr>td", text: nil.to_s, count: 2
    assert_select "tr>td", text: nil.to_s, count: 2
    assert_select "tr>td", text: nil.to_s, count: 2
    assert_select "tr>td", text: nil.to_s, count: 2
    assert_select "tr>td", text: "Engine".to_s, count: 2
    assert_select "tr>td", text: "Status".to_s, count: 2
    assert_select "tr>td", text: "MyText".to_s, count: 2
  end
end
