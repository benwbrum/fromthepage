FactoryBot.define do
  factory :collection do
    sequence(:title) { |n| "collection title #{n}"}

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
  factory :article
end

FactoryBot.define do
  factory :category
end

FactoryBot.define do
  # You will need to declare a `deed_type` within the spec
  factory :deed
end

FactoryBot.define do
  factory :user do
    sequence(:display_name) { |n| "User #{n} Display Name" }
    sequence(:login) { |n| "user_#{n}_login" }
    sequence(:email) { |n| "user_#{n}@sample.com" }
    password { 'password' }
    password_confirmation { 'password' }
  end
end
