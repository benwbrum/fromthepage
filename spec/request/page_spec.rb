require "rails_helper"
require 'json'

RSpec.describe "PageController", type: :request do
	  before do
	    @user = FactoryGirl.create(:user)
	    @collection = FactoryGirl.create(:collection)
   	    @work = FactoryGirl.create(:work)
   	    @page = FactoryGirl.create(:page)
	  end
#controllar que se reciba el acces token
	it 'create a page succes' do
	  	puts "-----------------Create a Page-------------------"
	    post '/api/page?auth_token='+@user.authentication_token.to_s+'&locale=es', {"work_id":@work.id.to_s,"page":{"title":"Page 1"},"subaction":"save_and_new"}
	    json = JSON.parse(response.body)
	  	puts json['message'];
	  	expect(json['status']).to eq("OK")
	end

	it 'show a page' do
	  	puts "----------------SHOW--------------------"
	  	get '/api/page/'+@page.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es'
	  	json = JSON.parse(response.body)
	  	puts json['message'];
	  	expect(json['status']).to eq("OK")
	end

	it 'updates a collection' do
	    puts "----------------UPDATE--------------------"
	  	patch '/api/page/'+@page.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es',{"page":{"title":"update"},"work_id":@page.work_id.to_s}
	  	json = JSON.parse(response.body)
	  	puts json['message']
	    expect(json['status']).to eq("OK")
	end


	it 'deletes a collection' do
	  	puts "--------------DELETE----------------------"
	  	delete '/api/page/'+@page.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es'   
	  	json = JSON.parse(response.body)
	  	puts json['message']
	    expect(json['status']).to eq("OK")
	end
end
