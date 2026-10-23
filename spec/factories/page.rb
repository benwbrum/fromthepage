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
    factory :transcribed_page, traits: [:transcribed]
    factory :page_with_links, traits: [:with_links]

    trait :with_legacy_image do
      base_image { 'images/pages/sanskrit.jpg' }
      base_width { 1581 }
      base_height { 570 }

      after(:build) do
        source = Rails.root.join('test_data/images/pages/sanskrit.jpg')
        dest_dir = Rails.root.join('public/images/pages')
        dest = dest_dir.join('sanskrit.jpg')

        FileUtils.mkdir_p(dest_dir)
        FileUtils.cp(source, dest) unless File.exist?(dest)
      end
    end

    trait :with_image do
      image do
        Rack::Test::UploadedFile.new(
          Rails.root.join("test_data/images/pages/sanskrit.jpg"),
          "image/jpeg"
        )
      end

      after(:build) do |page, evaluator|
        page.image.attach(evaluator.image)
      end
    end

    trait :with_source_text_change do
      after(:build) { |page, evaluator| page.source_text = evaluator.source_text }
    end
  end
end

FactoryBot.define do
  factory :page_article_link do
    sequence(:display_text) { |n| "display_text_#{n}" }
    article
  end
end

FactoryBot.define do
  factory :page_version
end
