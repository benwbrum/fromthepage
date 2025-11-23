FactoryBot.define do
  factory :suspicious_behavior do
    user
    collection
    behavior_type { 'paste_detected' }
    flagged_at { Time.current }
    status { 'pending' }
    metadata { { text_length: 100, timestamp: Time.current.iso8601 } }
    
    trait :with_page do
      page
    end
    
    trait :with_deed do
      deed
    end
    
    trait :resolved do
      status { 'dismissed' }
      resolved_at { Time.current }
      association :resolved_by_user, factory: :user
    end
    
    trait :approved do
      status { 'approved' }
      resolved_at { Time.current }
      association :resolved_by_user, factory: :user
    end
    
    trait :high_wpm do
      behavior_type { 'high_wpm' }
      metadata { { wpm: 500, timestamp: Time.current.iso8601 } }
    end
  end
end
