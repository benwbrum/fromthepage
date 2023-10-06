FactoryBot.define do
  factory :tag do
    tag_type { "MyString" }
    canonical { false }
    ai_text { "MyString" }
    message_key { "MyString" }
  end
end
