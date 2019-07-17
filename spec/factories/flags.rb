FactoryBot.define do
  factory :flag do
    author_user { nil }
    page_version { nil }
    article_version { nil }
    note { nil }
    provenance { "MyString" }
    status { "MyString" }
    snippet { "MyText" }
    comment { "MyText" }
    reporter_user { nil }
    auditor_user { nil }
  end
end
