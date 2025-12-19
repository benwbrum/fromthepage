FactoryBot.define do
  factory :external_api_request do
    user { nil }
    collection { nil }
    work { nil }
    page { nil }
    engine { "MyString" }
    status { "MyString" }
    params { "MyText" }
  end
end
