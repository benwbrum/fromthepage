require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to test the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator. If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails. There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.

RSpec.describe "/external_api_requests", type: :request do
  
  # This should return the minimal set of attributes required to create a valid
  # ExternalApiRequest. As you add validations to ExternalApiRequest, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  describe "GET /index" do
    it "renders a successful response" do
      ExternalApiRequest.create! valid_attributes
      get external_api_requests_url
      expect(response).to be_successful
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
      external_api_request = ExternalApiRequest.create! valid_attributes
      get external_api_request_url(external_api_request)
      expect(response).to be_successful
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_external_api_request_url
      expect(response).to be_successful
    end
  end

  describe "GET /edit" do
    it "renders a successful response" do
      external_api_request = ExternalApiRequest.create! valid_attributes
      get edit_external_api_request_url(external_api_request)
      expect(response).to be_successful
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new ExternalApiRequest" do
        expect {
          post external_api_requests_url, params: { external_api_request: valid_attributes }
        }.to change(ExternalApiRequest, :count).by(1)
      end

      it "redirects to the created external_api_request" do
        post external_api_requests_url, params: { external_api_request: valid_attributes }
        expect(response).to redirect_to(external_api_request_url(ExternalApiRequest.last))
      end
    end

    context "with invalid parameters" do
      it "does not create a new ExternalApiRequest" do
        expect {
          post external_api_requests_url, params: { external_api_request: invalid_attributes }
        }.to change(ExternalApiRequest, :count).by(0)
      end

      it "renders a successful response (i.e. to display the 'new' template)" do
        post external_api_requests_url, params: { external_api_request: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe "PATCH /update" do
    context "with valid parameters" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested external_api_request" do
        external_api_request = ExternalApiRequest.create! valid_attributes
        patch external_api_request_url(external_api_request), params: { external_api_request: new_attributes }
        external_api_request.reload
        skip("Add assertions for updated state")
      end

      it "redirects to the external_api_request" do
        external_api_request = ExternalApiRequest.create! valid_attributes
        patch external_api_request_url(external_api_request), params: { external_api_request: new_attributes }
        external_api_request.reload
        expect(response).to redirect_to(external_api_request_url(external_api_request))
      end
    end

    context "with invalid parameters" do
      it "renders a successful response (i.e. to display the 'edit' template)" do
        external_api_request = ExternalApiRequest.create! valid_attributes
        patch external_api_request_url(external_api_request), params: { external_api_request: invalid_attributes }
        expect(response).to be_successful
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested external_api_request" do
      external_api_request = ExternalApiRequest.create! valid_attributes
      expect {
        delete external_api_request_url(external_api_request)
      }.to change(ExternalApiRequest, :count).by(-1)
    end

    it "redirects to the external_api_requests list" do
      external_api_request = ExternalApiRequest.create! valid_attributes
      delete external_api_request_url(external_api_request)
      expect(response).to redirect_to(external_api_requests_url)
    end
  end
end
