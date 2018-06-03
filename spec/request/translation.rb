require "rails_helper"
require 'json'

RSpec.describe "TranscriptionController", type: :request do

  before do
    @user = FactoryGirl.create(:user)
    @translation = FactoryGirl.create(:translation)

  end

  it 'creates a translation' do
    puts "-----------------CREATE-------------------"
      #previous_length = Collection.count
      post '/api/translation?auth_token='+@user.authentication_token.to_s+'&locale=es',{"text":"text"}
      json = JSON.parse(response.body)
      puts json['message'];
      expect(json['status']).to eq("OK")
  end




  it 'updates a translation' do
    puts "----------------UPDATE--------------------"
  	patch '/api/translation/'+@translation.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es',{"text":"text"}
  	json = JSON.parse(response.body)
  	puts json['message']
    expect(json['status']).to eq("OK")
  end


  it 'deletes a translation' do
  	puts "--------------DELETE----------------------"
  	delete '/api/translation/'+@translation.id.to_s+'?auth_token='+@user.authentication_token.to_s+'&locale=es'
  	json = JSON.parse(response.body)
  	puts json['message']
    expect(json['status']).to eq("OK")
  end

end
