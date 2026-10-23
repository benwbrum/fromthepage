FactoryBot.define do
  factory :quality_sampling do
    user
    collection
    sample_set { [] }
  end
end
