FactoryBot.define do
  factory :collection do

    trait :with_links do
      works { build_stubbed_list :work_with_links, 2 }
    end
  end
end

FactoryBot.define do
  factory :work do
    sequence(:title) { |n| "Work #{n}" }
    sequence(:identifier) { |n| "work_id_#{n}" }
    trait :with_links do
      pages { build_stubbed_list :page_with_links, 2 }
    end
    
    factory :work_with_links, :traits => [:with_links]
  end
end

FactoryBot.define do
  factory :page do
    sequence(:title) { |n| "Page #{n}" }
    sequence(:position) { |n| n }
    
    trait :with_links do
      page_article_links { build_stubbed_list :page_article_link, 2 }
    end

    factory :page_with_links, :traits => [:with_links]
  end
end

FactoryBot.define do
  factory :page_article_link do
    sequence(:display_text) { |n| "display_text_#{n}" }
    article
  end
end

FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "Article #{n}" }
    categories { build_stubbed_list :category, 4 }
  end
end

FactoryBot.define do
  factory :category do
    sequence(:title) { |n| "Category #{n}" }
  end
end

