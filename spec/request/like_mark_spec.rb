require "rails_helper"
require 'json'

RSpec.describe "LikeMarkController", type: :request do
	before do

		#@admin = FactoryBot.create(:useradmin)
		@user = FactoryBot.create(:user)
		@work = FactoryBot.create(:work)
 		@page = FactoryBot.create(:page)

  end


	it 'like a transcription' do
		puts "-------------------Like a transcription-------------------"

		post '/api/transcription?auth_token='+@user.authentication_token.to_s+'&locale=es',{"text":"text"}
		json = JSON.parse(response.body)
		post '/api/mark?auth_token='+@user.authentication_token.to_s+'&locale=es',{"transcription_text":"mark test","coordinates":{"x":23,"y":34},"shape_type":"polyline","text_type":"body","page_id":42,"transcription_id":json['data']['id'],"transcription":json['data']}
		m = JSON.parse(response.body)
		patch '/api/transcription/'+json['data']['id'].to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es',{"text":"text","mark_id":m['data']['id']}
		get '/api/transcription/'+json['data']['id'].to_s+'/like?auth_token='+@user.authentication_token.to_s+'&locale=es'
		json = JSON.parse(response.body)
		puts json['message'];
		expect(json['status']).to eq("OK")
	end


	it 'dislike a transcription' do
		puts "-------------------Dislike a transcription-------------------"

		post '/api/transcription?auth_token='+@user.authentication_token.to_s+'&locale=es',{"text":"text"}
		json = JSON.parse(response.body)
		post '/api/mark?auth_token='+@user.authentication_token.to_s+'&locale=es',{"transcription_text":"mark test","coordinates":{"x":23,"y":34},"shape_type":"polyline","text_type":"body","page_id":42,"transcription_id":json['data']['id'],"transcription":json['data']}
		m = JSON.parse(response.body)
		patch '/api/transcription/'+json['data']['id'].to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es',{"text":"text","mark_id":m['data']['id']}
		get '/api/transcription/'+json['data']['id'].to_s+'/dislike?auth_token='+@user.authentication_token.to_s+'&locale=es'
		json = JSON.parse(response.body)
		puts json['message'];
		expect(json['status']).to eq("OK")
	end


end
