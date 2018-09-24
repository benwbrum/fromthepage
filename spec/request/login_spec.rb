require "rails_helper"
require 'json'

RSpec.describe "LoginController", type: :request do
	before do
		@user = FactoryBot.create(:user)
	end

#controllar que se reciba el acces token
	it 'attemp login succes' do
  		puts "-------------------Login Success Test-------------------"
	    post '/api/login?locale=es',{"username":"testuser","password":"abc12356"}
	    json = JSON.parse(response.body)
      puts json['message'];
      expect(json['status']).to eq("OK")
	end

#falla el login si le erras de password
  it 'attemp login fail' do
      puts "-------------------Login Fail-------------------"
      post '/api/login?locale=es',{"username":"failtest","password":"pedro1234"}
      json = JSON.parse(response.body)
      puts json['message'];
      expect(json['status']).to eq("ERROR")
  end

end
