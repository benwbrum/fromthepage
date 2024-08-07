FactoryBot.define do
  factory :page_processing_job do
    status { "MyString" }
    ai_job { nil }
    page { nil }
  end
end
