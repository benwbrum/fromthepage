require "rails_helper"
require 'json'

RSpec.describe "ForumController", type: :request do

  before do
    @user = FactoryBot.create(:user)
    @transcription = FactoryBot.create(:transcription)
    @forum = FactoryBot.create(:foro)
  end

	it 'create a Forum' do
		puts "-------------------CREATE-------------------"
	  post '/api/foro?auth_token='+@user.authentication_token.to_s+'&locale=es',{"element":{"id": 2,"className":"Transcription"}}
	  json = JSON.parse(response.body)
	  puts json['message'];
    expect(json['status']).to eq("OK")
	end



  it 'delete a Forum' do
  	puts "-------------------DELETE-------------------"
  	delete '/api/foro/1?auth_token='+@user.authentication_token.to_s+'&locale=es'
  	json = JSON.parse(response.body)
  	puts json['message']
    expect(json['status']).to eq("OK")
  end

end
