# frozen_string_literal: true

FactoryBot.define do
  factory :collection do
    sequence(:title) { |n| "Collection Title #{n}" }
    owner_user_id { association(:owner).id }
    works { build_list :work_with_pages, 2 }

    trait :with_links do
      works { build_stubbed_list :work_with_links, 2 }
    end
    trait :with_pages do
      works { build_list :work_with_pages, 2 }
    end
    trait :private do
      restricted { true }
    end
    trait :docset_enabled do
      supports_document_sets { true }
    end
  end
end
