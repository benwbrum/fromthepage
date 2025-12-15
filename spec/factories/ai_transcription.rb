FactoryBot.define do
  factory :ai_transcription do
    source_text { 'Sample AI text' }
    page_id { association(:page).id }
    model { 'gemini-3-pro-preview' }
    metadata { nil }
    reasoning { 'Sample AI reasoning' }
  end
end
