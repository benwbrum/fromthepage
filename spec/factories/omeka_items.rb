# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :omeka_item do
    title "MyString"
    subject "MyString"
    description "MyString"
    rights "MyString"
    creator "MyString"
    format "MyString"
    coverage "MyString"
    omeka_site_id 1
    omeka_id 1
    omeka_url "MyString"
    omeka_collection_id 1
    user_id 1
  end
end
