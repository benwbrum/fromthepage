require 'faker'
FactoryGirl.define do

  #A simple user
  factory :user do
	id 22
  	login 'testuser'
    display_name 'Test'
	email 'testuser@transcriptor.com'
   	password 'abc12356'
   	password_confirmation 'abc12356'
   #	token 'test'
  end
end


   