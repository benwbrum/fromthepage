FactoryBot.define do
  factory :bulk_export do
    collection_id { association(:collection).id }
    user_id { association(:user).id }

    trait :new do
      status { BulkExport::Status::NEW }
    end

    trait :queued do
      status { BulkExport::Status::QUEUED }
    end

    trait :processing do
      status { BulkExport::Status::PROCESSING }
    end

    trait :finished do
      status { BulkExport::Status::FINISHED }
    end

    trait :cleaned do
      status { BulkExport::Status::CLEANED }
    end

    trait :error do
      status { BulkExport::Status::ERROR }
    end
  end
end
