FactoryBot.define do
  factory :ai_result do
    job_type { "MyString" }
    engine { "MyString" }
    parameters { "MyString" }
    status { "MyString" }
    result { "MyString" }
    page { nil }
    work { nil }
    collection { nil }
    user { nil }
    ai_job { nil }
  end
end
