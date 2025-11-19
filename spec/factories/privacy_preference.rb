FactoryBot.define do
  factory :privacy_preference do
    analytics { true }
    marketing { true }
    recorded { true }
    user_id { association(:user).id }
  end
end
