FactoryBot.define do
  factory :note do
    sequence(:title) { |n| "Note Title #{n}" }
    sequence(:body) { |n| "Note Title #{n}" }
  end
end
