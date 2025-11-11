FactoryBot.define do
  factory :privacy_preference do
    recorded { true }
    analytics { true }
    marketing { true }
  end
end
