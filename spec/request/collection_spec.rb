require "rails_helper"
require 'json'

RSpec.describe "CollectionController", type: :request do
	

	it 'creates a Collection' do
		puts "-----------------CREATE-------------------"
	    previous_length = Collection.count
	    post '/api/collection?auth_token=test2&locale=es',{collection:{title:"Collection  create test"}}
	    json = JSON.parse(response.body)
	  	puts json['message'];
	end


  it 'show a collection' do
  	puts "----------------SHOW--------------------"
  	post '/api/collection?auth_token=test2&locale=es',{collection:{title:"Collection for view for show test"}}
	json = JSON.parse(response.body)
    get '/api/collection/'+json['data']['id'].to_s+'?auth_token=test2&locale=es' 
  	json = JSON.parse(response.body)
  	puts json['message'];
  end

  it 'updates a collection' do
  	puts "--------------UPDATE----------------------"
  	post '/api/collection?auth_token=s_ieEsjnV8728pxCG9ri&locale=es',{collection:{title:"Collection for update test"}}
  	json = JSON.parse(response.body)
 	patch '/api/collection/'+json['data']['id'].to_s+'?auth_token=test2&locale=es',{collection:{title:"update"}}   
  	json = JSON.parse(response.body)
  	puts json['message'];
  end


  it 'deletes a collection' do
  	puts "--------------DELETE----------------------"
  	post '/api/collection?auth_token=s_ieEsjnV8728pxCG9ri&locale=es',{collection:{title:"Collection for delete test"}}
  	json = JSON.parse(response.body)
 	delete '/api/collection/'+json['data']['id'].to_s+'?auth_token=test2&locale=es' ,{collection:{title:"update"}}   
  	json = JSON.parse(response.body)
  	puts json['message'];
    
  end

end