FactoryGirl.define do

  factory :collection_owner do
    # :user
    :user2
  end
  

  factory :collection do
    title  "joejoejoe"
    intro_block  "password"
    footer_block  "password"
    # restricted 0
    # :collection_owner
    association :owner_user_id, factory: :user
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
