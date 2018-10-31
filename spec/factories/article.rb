FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "Article Title #{n}" }
  end
end
