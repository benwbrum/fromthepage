require "rails_helper"
require 'json'

RSpec.describe "UserController", type: :request do
	before do
		@user = FactoryGirl.create(:user)
	
	end
#controllar que se reciba el acces token
	it 'attemp update user succes' do
  		puts "-----------------Update user success-----------------"

		   	put '/api/user/'+@user.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=en',{"user":{"display_name":"update test","website":"NOTOWNER","about":"NOTOWNER"}}
	      json = JSON.parse(response.body)
		  	puts json['message'];
      	puts json['data'];
      	expect(json['message']).to eq("User has been updated")
#      	expect(response).to be_success
	end



end
