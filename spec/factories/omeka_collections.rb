# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :omeka_collection do
    omeka_id 1
    collection_id 1
    title "MyString"
    description "MyString"
    omeka_site_id 1
  end
end
