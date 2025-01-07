FactoryBot.define do
  factory :transcription_field do
    label { 'Label' }
    collection_id { association(:collection).id }

    trait :as_metadata do
      field_type { TranscriptionField::FieldType::METADATA }
    end
  end
end
