FactoryGirl.define do

  factory :work do
    title  "joejoejoe"
    description  "password"
    # I did not think this would work
    owner_user_id FactoryGirl.build(:user).id
  end
=begin
  factory :user2, class: User do
    login  "moemoemoe"
    password  "password"
    password_confirmation  "password"
    display_name  "moemoemoe"
    print_name  "moemoemoe"
    email  "moe@example.com"
  end
=end
end
