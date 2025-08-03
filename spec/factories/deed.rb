FactoryBot.define do
  # You will need to declare a `deed_type` within the spec
  factory :deed do
    deed_type { DeedType::PAGE_TRANSCRIPTION }
    collection
    user
    created_at { 1.day.ago }
  end
end
