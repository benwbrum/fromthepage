require 'rails_helper'

RSpec.describe "DocumentUploads", :type => :request do
  describe "GET /document_uploads" do
    it "works! (now write some real specs)" do
      get document_uploads_path
      expect(response.status).to be(200)
    end
  end
end
