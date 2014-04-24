require "spec_helper"

describe OmekaItemsController do
  describe "routing" do

    it "routes to #index" do
      get("/omeka_items").should route_to("omeka_items#index")
    end

    it "routes to #new" do
      get("/omeka_items/new").should route_to("omeka_items#new")
    end

    it "routes to #show" do
      get("/omeka_items/1").should route_to("omeka_items#show", :id => "1")
    end

    it "routes to #edit" do
      get("/omeka_items/1/edit").should route_to("omeka_items#edit", :id => "1")
    end

    it "routes to #create" do
      post("/omeka_items").should route_to("omeka_items#create")
    end

    it "routes to #update" do
      put("/omeka_items/1").should route_to("omeka_items#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/omeka_items/1").should route_to("omeka_items#destroy", :id => "1")
    end

  end
end
