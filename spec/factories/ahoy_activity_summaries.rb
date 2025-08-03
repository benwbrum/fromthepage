FactoryBot.define do
  factory :ahoy_activity_summary do
    collection
    user
    date { 1.day.ago }
    minutes { 30 }
    activity { 'page_edit' }
  end
end
