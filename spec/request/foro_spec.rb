require "rails_helper"
require 'json'

RSpec.describe "ForumController", type: :request do

  before do
    @user = FactoryGirl.create(:user)
    @transcription = FactoryGirl.create(:transcription)
    @forum = FactoryGirl.create(:foro)
  end

	it 'creates a Forum' do
		puts "-----------------CREATE-------------------"
    puts "/api/foro?auth_token="+@user.authentication_token.to_s+"&locale=es"
	    #previous_length = Collection.count
	    post '/api/foro?auth_token='+@user.authentication_token.to_s+'&locale=es',{"element":{"id": 2,"className":"Transcription"}}
	    json = JSON.parse(response.body)
	  	puts json['message'];
      expect(json['status']).to eq("OK")
	end



  it 'deletes a Forum' do
  	puts "--------------DELETE----------------------"
  	delete '/api/foro/1?auth_token='+@user.authentication_token.to_s+'&locale=es'
  	json = JSON.parse(response.body)
  	puts json['message']
    expect(json['status']).to eq("OK")
  end

end
