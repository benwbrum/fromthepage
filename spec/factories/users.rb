FactoryGirl.define do

  factory :user1, class: User do
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

end
