require "rails_helper"

RSpec.describe ExternalApiRequestsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/external_api_requests").to route_to("external_api_requests#index")
    end

    it "routes to #new" do
      expect(get: "/external_api_requests/new").to route_to("external_api_requests#new")
    end

    it "routes to #show" do
      expect(get: "/external_api_requests/1").to route_to("external_api_requests#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/external_api_requests/1/edit").to route_to("external_api_requests#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/external_api_requests").to route_to("external_api_requests#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/external_api_requests/1").to route_to("external_api_requests#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/external_api_requests/1").to route_to("external_api_requests#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/external_api_requests/1").to route_to("external_api_requests#destroy", id: "1")
    end
  end
end
