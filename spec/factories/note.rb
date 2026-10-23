FactoryBot.define do
  factory :note do
    sequence(:title) { |n| "Note Title #{n}" }
    sequence(:body) { |n| "Note Title #{n}" }

    association :user
    association :collection
    association :work
    association :page
  end
end
