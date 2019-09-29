FactoryBot.define do
  factory :work do
    sequence(:title) { |n| "Work Title #{n}" }
    sequence(:identifier) { |n| "work_id_#{n}" }

    trait :with_links do
      pages { build_stubbed_list :page_with_links, 2 }
    end

    trait :with_pages do
      pages { build_list :page, 2 }
    end

    trait :transcribed do
      pages { build_list :transcribed_page, 2 }
    end

    trait :restricted do
      restrict_scribes { true }
    end

    factory :work_with_links, :traits => [:with_links]
    factory :work_with_pages, :traits => [:with_pages]
  end
end
