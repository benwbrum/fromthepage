FactoryBot.define do
  factory :document_set do
    sequence(:title) { |n| "DocumentSet Title #{n}" }
    collection_id { association(:collection).id }
    owner_user_id { association(:user).id }
  end
end
