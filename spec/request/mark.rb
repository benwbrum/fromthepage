require "rails_helper"
require 'json'

RSpec.describe "MarkController", type: :request do
	before do
    @user = FactoryGirl.create(:user)
    @collection = FactoryGirl.create(:collection)
    @work = FactoryGirl.create(:work)
    @page = FactoryGirl.create(:page)

  end
  it 'creates a Mark' do
	   	puts "-----------------CREATE-------------------"
	    post '/api/mark?auth_token=test&locale=es',{"text":"mark test","coordinates":{"x":23,"y":34},"shape_type":"polyline","text_type":"body","page_id":42}
	    json = JSON.parse(response.body)
      puts json['message'];
      expect(json['status']).to eq("OK")
	end


end

