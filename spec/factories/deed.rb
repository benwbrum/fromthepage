FactoryBot.define do
  factory :deed do
    deed_type { DeedType::PAGE_TRANSCRIPTION }
    association :user
    association :collection
    association :work
  end
end
