require 'rails_helper'

RSpec.describe "external_api_requests/show", type: :view do
  before(:each) do
    @external_api_request = assign(:external_api_request, ExternalApiRequest.create!(
      user: nil,
      collection: nil,
      work: nil,
      page: nil,
      engine: "Engine",
      status: "Status",
      params: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Engine/)
    expect(rendered).to match(/Status/)
    expect(rendered).to match(/MyText/)
  end
end
