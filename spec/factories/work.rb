require 'faker'
FactoryBot.define do
  #A simple work
  factory :work do
  	id  42
    title "work test"
 	description "a work for test"
 	slug ""
 	owner_user_id 22
 	collection_id 42
  end
end
