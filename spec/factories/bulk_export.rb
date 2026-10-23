FactoryBot.define do
  factory :bulk_export do
    collection_id { association(:collection).id }
    user_id { association(:user).id }
    status { :new }

    trait :new do
      status { :new }
    end

    trait :queued do
      status { :queued }
    end

    trait :processing do
      status { :processing }
    end

    trait :finished do
      status { :finished }
    end

    trait :cleaned do
      status { :cleaned }
    end

    trait :error do
      status { :error }
    end
  end
end
