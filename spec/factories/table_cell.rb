FactoryBot.define do
  factory :table_cell do
    header { 'Header' }
    content { 'Content' }
    row { 0 }

    transcription_field_id { association(:transcription_field).id }
    work_id { association(:work).id }
    page_id { association(:page).id }
  end
end
