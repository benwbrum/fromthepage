FactoryBot.define do
  factory :metadata_coverage do
    collection
    sequence(:key) { |n| "metadata_key_#{n}" }
    count { 0 }
  end
end
