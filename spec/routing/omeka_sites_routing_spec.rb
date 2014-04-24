require "spec_helper"

describe OmekaSitesController do
  describe "routing" do

    it "routes to #index" do
      get("/omeka_sites").should route_to("omeka_sites#index")
    end

    it "routes to #new" do
      get("/omeka_sites/new").should route_to("omeka_sites#new")
    end

    it "routes to #show" do
      get("/omeka_sites/1").should route_to("omeka_sites#show", :id => "1")
    end

    it "routes to #edit" do
      get("/omeka_sites/1/edit").should route_to("omeka_sites#edit", :id => "1")
    end

    it "routes to #create" do
      post("/omeka_sites").should route_to("omeka_sites#create")
    end

    it "routes to #update" do
      put("/omeka_sites/1").should route_to("omeka_sites#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/omeka_sites/1").should route_to("omeka_sites#destroy", :id => "1")
    end

  end
end
