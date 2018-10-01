require 'faker'
FactoryBot.define do
  factory :useradmin,  class: User do
  	login {"adminuser"}
    display_name {'Admin'}
	  email {'testuseradmin@transcriptor.com'}
   	password {'abc12356'}
   	password_confirmation {'abc12356'}
  end

end
