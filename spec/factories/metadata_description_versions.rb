FactoryBot.define do
  factory :metadata_description_version do
    metadata_description { 'MyText' }
    user { nil }
    work { nil }
    version_number { 1 }
  end
end
