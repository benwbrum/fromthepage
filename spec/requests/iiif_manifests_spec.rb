require 'spec_helper'

describe "IIIF Manifests API", :type => :request do
  fixtures :all

  it "returns JSON" do
    get iiif_manifest_path(1)
    expect(response.content_type).to eq("application/json")
  end

  it "returns a URL with the corresponding ID" do
    get iiif_manifest_path(1)
    json = JSON.parse(response.body)
    expect(json['within']['@id']).to eql("http://www.example.com/iiif/collection/1")
  end
end
