require 'spec_helper'

describe "IIIF Manifests API", :type => :request do
  it "returns JSON" do
    get "/iiif/1/manifest"
    expect(response.content_type).to eq("application/json")
  end

  it "returns a URL with the corresponding ID" do
    get "/iiif/1/manifest"
    json = JSON.parse(response.body)
    expect(json['within']['@id']).to eql("http://www.example.com/iiif/collection/1")
  end
end
