FactoryBot.define do
  factory :article do
    sequence(:title) { |n| "Article Title #{n}" }
  end

  factory :article_article_link do
    association :source_article, factory: :article
    association :target_article, factory: :article
  end
end

FactoryBot.define do
  factory :article_version do
    article
    user
    sequence(:title) { |n| "Article Version #{n}" }
    source_text { 'Version text' }
    created_on { Time.current }
  end
end
