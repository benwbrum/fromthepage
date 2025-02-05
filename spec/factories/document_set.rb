FactoryBot.define do
  factory :document_set do
    sequence(:title) { |n| "DocumentSet Title #{n}" }
    collection_id { association(:collection, :docset_enabled).id }
    owner_user_id { association(:owner).id }

    trait :public do
      # Document Sets are private by default!
      is_public { true }
    end

    trait :private do
      # Document Sets are private by default!
      is_public { false }
    end

    trait :with_picture do
      picture { Rack::Test::UploadedFile.new(Rails.root.join('test_data/uploads/document_set_image.jpg'), 'image/jpeg') }
    end
  end
end
