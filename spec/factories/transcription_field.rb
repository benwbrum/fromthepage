FactoryBot.define do
  factory :transcription_field do
    label { 'Label' }
    collection_id { association(:collection).id }

    trait :as_metadata do
      field_type { TranscriptionField::FieldType::METADATA }
    end

    trait :as_transcription do
      field_type { TranscriptionField::FieldType::TRANSCRIPTION }
    end

    trait :text_field do
      input_type { 'text' }
    end

    trait :select_field do
      input_type { 'select' }
      options { 'Option A;Option B;Option C' }
    end

    trait :date_field do
      input_type { 'date' }
    end

    trait :spreadsheet_field do
      input_type { 'spreadsheet' }
    end

    trait :description_field do
      input_type { 'description' }
    end

    trait :instruction_field do
      input_type { 'instruction' }
    end
  end
end
