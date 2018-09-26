FactoryBot.define do
  factory :work do
    collection { association(:collection) }
    sequence(:title) { |n| "title_#{n}" }
  end
end
