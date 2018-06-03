require "rails_helper"
require 'json'

RSpec.describe "TranscriptionController", type: :request do

  before do
    @user = FactoryGirl.create(:user)
    @contribution = FactoryGirl.create(:contribution)

  end

  it 'creates a transcription' do
    puts "-----------------CREATE-------------------"
      #previous_length = Collection.count
      post '/api/transcription?auth_token='+@user.authentication_token.to_s+'&locale=es',{"text":"text"}
      json = JSON.parse(response.body)
      puts json['message'];
      expect(json['status']).to eq("OK")
  end


  it 'show a transcription' do
  	puts "----------------SHOW--------------------"
  	get '/api/transcription/'+@contribution.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es'
  	json = JSON.parse(response.body)
  	expect(json['status']).to eq("OK")
  end

  it 'updates a transcription' do
    puts "----------------UPDATE--------------------"
  	patch '/api/transcription/'+@contribution.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es',{"text":"text"}   
  	json = JSON.parse(response.body)
  	puts json['message']
    expect(json['status']).to eq("OK")
  end


  it 'deletes a transcription' do
  	puts "--------------DELETE----------------------"
  	delete '/api/transcription/'+@contribution.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es'
  	json = JSON.parse(response.body)
  	puts json['message']
    expect(json['status']).to eq("OK")
  end

end
