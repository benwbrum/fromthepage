FactoryBot.define do
  factory :spreadsheet_column do
    transcription_field { nil }
    position { 1 }
    label { "MyString" }
    input_type { "MyString" }
    options { "MyString" }
    percentage { 1 }
  end
end
