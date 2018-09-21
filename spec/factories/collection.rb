FactoryBot.define do
  factory :collection do
    owner_user { association(:owner_user) }

    sequence(:title) { |n| "title_#{n}" }
    sequence(:intro_block) { |n| "intro_block_#{n}" }
    sequence(:footer_block) { |n| "footer_block_#{n}" }
    sequence(:picture) { |n| "picture_#{n}.jpg" }
    sequence(:transcription_conventions) { |n| "transcription_conventions_#{n}" }
    sequence(:slug) { |n| "slug_#{n}" }
    sequence(:help) { |n| "help_#{n}" }
    sequence(:link_help) { |n| "link_help_#{n}" }
    sequence(:language) { |n| "language_#{n}" }
    sequence(:text_language) { |n| "text_language_#{n}" }
    sequence(:license_key) { |n| "license_key_#{n}" }
    sequence(:pct_completed) { |n| n }
    sequence(:default_orientation) { |n| "default_orientation_#{n}" }
    supports_document_sets { false }
    restricted { false }
    hide_completed { true }
    subjects_disabled { false }
    review_workflow { false }
    field_based { false }
    voice_recognition { false }
  end
end
