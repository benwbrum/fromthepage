FactoryBot.define do
  factory :ai_work_metadata do
    work_id { association(:work).id }
    model { 'gemini-3.7-flash' }
    prompt { 'Sample AI prompt' }
    metadata { nil }
    metadata_json { nil }
    reasoning { 'Sample AI reasoning' }
    status { :new }
  end
end
