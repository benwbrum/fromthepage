FactoryGirl.define do

  factory :user do
    login  "joejoejoe"
    password  "password"
    password_confirmation  "password"
    display_name  "joejoejoe"
    print_name  "joejoejoe"
    email  "joe@example.com"
  end

  factory :user2, class: User do
    login  "moemoemoe"
    password  "password"
    password_confirmation  "password"
    display_name  "moemoemoe"
    print_name  "moemoemoe"
    email  "moe@example.com"
  end

=begin

  factory :user2, class: User do
    provider "twitter"
    uid "12346"
    name "Jimmy 2"
    id 2
    number_of_sites 0
  end

  factory :user_create, class: User do
    provider "twitter"
    uid "12346"
    name "Jimmy 2"
    
    number_of_sites 0
  end
=end
end
