FactoryBot.define do
  factory :page_processing_task do
    type { "" }
    position { 1 }
    status { "MyString" }
    page_processing_job { nil }
  end
end
