FactoryBot.define do
  factory :collection do
    sequence(:title) { |n| "Collection Title #{n}" }
    sequence(:slug)  { |n| "collection-title-#{n}" }
    owner_user_id { association(:user).id }

    trait :with_links do
      works { build_stubbed_list :work_with_links, 2 }
    end

    trait :with_pages do
      works { build_list :work_with_pages, 2 }
    end
  end
end
