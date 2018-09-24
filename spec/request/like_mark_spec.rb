require "rails_helper"
require 'json'

RSpec.describe "MarkController", type: :request do
	before do
    @mark = FactoryBot.create(:mark)
    @transcription = @mark.transcription
    @user = @mark.transcription.user
    @transcription.mark = @mark

  end
  it 'like a trasncription' do
      puts "-------------------LIKE-------------------"


      puts @mark.to_json
      puts '-----------'
      puts @transcription.id
      puts @transcription.to_json
      puts '/api/transcription/'+@transcription.id.to_s+'/like?auth_token='+@user.authentication_token.to_s+'&locale=es'
      get '/api/transcription/'+@transcription.id.to_s+'/like?auth_token='+@user.authentication_token.to_s+'&locale=es'
      json = JSON.parse(response.body)
      puts json['message'];
      expect(json['status']).to eq("OK")
  end

end
