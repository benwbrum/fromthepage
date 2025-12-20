FactoryBot.define do
  factory :suspicious_behavior do
    behavior_type { :large_paste }
    status { :pending }
    user_id { association(:user).id }
    collection_id { association(:collection).id }
    page_id { association(:page).id }
    resolved_at { nil }
    resolved_by_user_id { association(:owner).id }
  end
end
