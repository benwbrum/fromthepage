FactoryBot.define do
  factory :spreadsheet_column do
    label { 'Label' }
    transcription_field_id { association(:transcription_field).id }
  end
end
