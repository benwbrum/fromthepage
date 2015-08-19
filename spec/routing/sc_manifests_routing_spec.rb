require "rails_helper"

RSpec.describe ScManifestsController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/sc_manifests").to route_to("sc_manifests#index")
    end

    it "routes to #new" do
      expect(:get => "/sc_manifests/new").to route_to("sc_manifests#new")
    end

    it "routes to #show" do
      expect(:get => "/sc_manifests/1").to route_to("sc_manifests#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/sc_manifests/1/edit").to route_to("sc_manifests#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/sc_manifests").to route_to("sc_manifests#create")
    end

    it "routes to #update" do
      expect(:put => "/sc_manifests/1").to route_to("sc_manifests#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/sc_manifests/1").to route_to("sc_manifests#destroy", :id => "1")
    end

  end
end
