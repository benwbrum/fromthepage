# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :omeka_file do
    omeka_id 1
    omeka_item_id 1
    mime_type "MyString"
    fullsize_url "MyString"
    thumbnail_url "MyString"
    original_filename "MyString"
    omeka_order 1
  end
end
