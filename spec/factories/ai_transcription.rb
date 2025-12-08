FactoryBot.define do
  factory :ai_transcription do
    source_text { 'Sample AI text' }
    page_id { association(:page).id }
    model { 'gemini-2.5-pro' }
    metadata { nil }
    reasoning { 'Sample AI reasoning' }
  end
end
