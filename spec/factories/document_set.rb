FactoryBot.define do
  factory :document_set do
    sequence(:title) { |n| "DocumentSet Title #{n}" }
    collection_id { association(:collection, :docset_enabled).id }
    owner_user_id { association(:owner).id }

    trait :public do
      visibility { :public }
    end

    trait :private do
      visibility { :private }
    end

    trait :read_only do
      visibility { :read_only }
    end

    trait :with_picture do
      picture { Rack::Test::UploadedFile.new(Rails.root.join('test_data/uploads/document_set_image.jpg'), 'image/jpeg') }
    end
  end
end
