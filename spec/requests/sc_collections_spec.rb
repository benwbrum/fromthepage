require 'rails_helper'

RSpec.describe "ScCollections", :type => :request do
  describe "GET /sc_collections" do
    it "works! (now write some real specs)" do
      get sc_collections_path
      expect(response.status).to be(200)
    end
  end
end
