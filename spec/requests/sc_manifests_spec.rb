require 'rails_helper'

RSpec.describe "ScManifests", :type => :request do
  describe "GET /sc_manifests" do
    it "works! (now write some real specs)" do
      get sc_manifests_path
      expect(response.status).to be(200)
    end
  end
end
