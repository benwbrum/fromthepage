FactoryBot.define do
  factory :collection do
    sequence(:title) { |n| "title_#{n}" }
  end
end
