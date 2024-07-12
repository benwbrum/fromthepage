FactoryBot.define do
  factory :page do
    sequence(:title) { |n| "Page Title #{n}" }
    sequence(:position) { |n| n }

    trait :with_links do
      page_article_links { build_stubbed_list :page_article_link, 2 }
    end

    trait :transcribed do
      status { :transcribed }
    end
    factory :transcribed_page, :traits => [:transcribed]
    factory :page_with_links, :traits => [:with_links]
  end
end

FactoryBot.define do
  factory :page_article_link do
    sequence(:display_text) { |n| "display_text_#{n}" }
    article
  end
end
