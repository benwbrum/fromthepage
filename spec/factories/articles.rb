FactoryGirl.define do

  factory :article do
    title  "joejoejoe"
    source_text  "password"
    lock_version 0
    collection_id 1
  end

=begin
  factory :article_version do
    title "hjoehjoe"
    source_text "jdjdjddj"
    :article
  end
=end
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
