FactoryBot.define do
  factory :category do
    title { "Category #{SecureRandom.uuid}" }
  end
end
