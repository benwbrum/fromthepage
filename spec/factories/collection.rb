# frozen_string_literal: true

FactoryBot.define do
  factory :collection do
    sequence(:title) { |n| "Collection Title #{n}" }
    owner_user_id { association(:owner).id }
    subjects_disabled { false }
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

    trait :with_picture do
      picture { Rack::Test::UploadedFile.new(Rails.root.join('test_data/uploads/collection_image.jpg'), 'image/jpeg') }
    end

    trait :review_required do
      review_type { :required }
    end
  end
end
