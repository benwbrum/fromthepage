require "rails_helper"
require 'json'

RSpec.describe "WorkController", type: :request do
	before do
		@user = FactoryGirl.create(:user)
		@collection = FactoryGirl.create(:collection)
		@work = FactoryGirl.create(:work)
	end


	it 'create a work succes' do
		puts "-----------------Create a Work-------------------"
	    post '/api/work?auth_token='+@user.authentication_token.to_s+'&locale=en', {"work":{"collection_id": @collection.id.to_s,"title":"trabajo test","description":""},"button":""}
	    json = JSON.parse(response.body)
	  	puts json['message']
	  	puts json['data']
	  	expect(json['status']).to eq("OK")
	end
	it 'show a work' do
	  	puts "----------------SHOW--------------------"
	  	get '/api/work/'+@work.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es'
	  	json = JSON.parse(response.body)
	  	puts json['message']
	  	expect(json['status']).to eq("OK")
	end

	it 'updates a work' do
	    puts "----------------UPDATE--------------------"
	  	patch '/api/work/'+@work.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es',{"work":{"collection":{"id":@collection.id.to_s},"title":"update","slug":"otro test"}}
	  	json = JSON.parse(response.body)
	  	puts json['message']
	    expect(json['status']).to eq("OK")
	end


	it 'deletes a work' do
	  	puts "--------------DELETE----------------------"
	  	delete '/api/work/'+@work.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es'   
	  	json = JSON.parse(response.body)
	  	puts json['message']
	    expect(json['status']).to eq("OK")
	end

end
