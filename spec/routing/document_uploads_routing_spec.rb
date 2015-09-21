require "rails_helper"

RSpec.describe DocumentUploadsController, :type => :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/document_uploads").to route_to("document_uploads#index")
    end

    it "routes to #new" do
      expect(:get => "/document_uploads/new").to route_to("document_uploads#new")
    end

    it "routes to #show" do
      expect(:get => "/document_uploads/1").to route_to("document_uploads#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/document_uploads/1/edit").to route_to("document_uploads#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/document_uploads").to route_to("document_uploads#create")
    end

    it "routes to #update" do
      expect(:put => "/document_uploads/1").to route_to("document_uploads#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/document_uploads/1").to route_to("document_uploads#destroy", :id => "1")
    end

  end
end
