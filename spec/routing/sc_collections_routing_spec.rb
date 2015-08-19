require "rails_helper"

RSpec.describe ScCollectionsController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/sc_collections").to route_to("sc_collections#index")
    end

    it "routes to #new" do
      expect(:get => "/sc_collections/new").to route_to("sc_collections#new")
    end

    it "routes to #show" do
      expect(:get => "/sc_collections/1").to route_to("sc_collections#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/sc_collections/1/edit").to route_to("sc_collections#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/sc_collections").to route_to("sc_collections#create")
    end

    it "routes to #update" do
      expect(:put => "/sc_collections/1").to route_to("sc_collections#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/sc_collections/1").to route_to("sc_collections#destroy", :id => "1")
    end

  end
end
