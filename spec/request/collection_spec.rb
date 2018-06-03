require "rails_helper"
require 'json'

RSpec.describe "CollectionController", type: :request do

  before do
    @user = FactoryGirl.create(:user)
    @collection = FactoryGirl.create(:collection)
  end

	it 'creates a Collection' do
		puts "-----------------CREATE-------------------"
	    #previous_length = Collection.count
	    post '/api/collection?auth_token='+@user.authentication_token.to_s+'&locale=es',{collection:{title:"Collection  create test"}}
	    json = JSON.parse(response.body)
	  	puts json['message'];
      expect(json['status']).to eq("OK")
	end


  it 'show a collection' do
  	puts "----------------SHOW--------------------"
  	get '/api/collection/'+@collection.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es'
  	json = JSON.parse(response.body)
  	expect(json['status']).to eq("OK")
  end

  it 'updates a collection' do
    puts "----------------UPDATE--------------------"
  	patch '/api/collection/'+@collection.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es',{collection:{title:"update"}}
  	json = JSON.parse(response.body)
  	puts json['message']
    expect(json['status']).to eq("OK")
  end


  it 'deletes a collection' do
  	puts "--------------DELETE----------------------"
  	delete '/api/collection/'+@collection.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es'
  	json = JSON.parse(response.body)
  	puts json['message']
    expect(json['status']).to eq("OK")
  end

end
