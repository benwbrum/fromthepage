FactoryBot.define do
  factory :ai_job do
    job_type { "MyString" }
    engine { "MyString" }
    parameters { "MyString" }
    status { "MyString" }
    page { nil }
    work { nil }
    collection { nil }
    user { nil }
  end
end
