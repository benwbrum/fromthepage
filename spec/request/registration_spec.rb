require "rails_helper"
require 'json'

RSpec.describe "RegistrationController", type: :request do
	before do
		@user = FactoryGirl.create(:user)
	end
	
#controllar que se reciba el acces token
	it 'register an user succes' do
		puts "-----------------Register Success test-------------------"
		puts "INFO: "
	    post '/api/registration?locale=es', {"user":{"login":"test7500", "email":"test2@transcriptor.com", "password":"lucas1234", "password_confirmation":"lucas1234", "display_name":"Lucas"}}
	    json = JSON.parse(response.body)
	  	puts json['message'];
	  	expect(json['status']).to eq("OK")
	end

	it 'register an user fail' do
		puts "-----------------Register Fail test-------------------"
		puts "INFO: attemp regis with existing username"
	    post '/api/registration?locale=es', {"user":{"login":"testuser", "email":"test2@transcriptor.com", "password":"lucas1234", "password_confirmation":"lucas1234", "display_name":"Lucas"}}
	    json = JSON.parse(response.body)
	  	puts json['message'];
	  	expect(json['status']).to eq("ERROR")
	end


end