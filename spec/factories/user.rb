require 'faker'
FactoryBot.define do
  factory :user do
    id 33
  	login {"testuser"}
    display_name {'Test'}
	  email {'testuser@transcriptor.com'}
   	password {'abc12356'}
   	password_confirmation {'abc12356'}
  end

end
