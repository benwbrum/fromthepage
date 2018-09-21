FactoryBot.define do
  factory :work do
    # owner_user { association(:owner_user) }
    # collection { association(:collection) }

    sequence(:title) { |n| "title_#{n}" }
    sequence(:description) { |n| "description_#{n}" }
    sequence(:restrict_scribes) { false }
    sequence(:transcription_version) { |n| n }
    sequence(:physical_description) { |n| "physical_description_#{n}" }
    sequence(:document_history) { |n| "document_history_#{n}" }
    sequence(:permission_description) { |n| "permission_description_#{n}" }
    sequence(:location_of_composition) { |n| "location_of_composition_#{n}" }
    sequence(:author) { |n| "author_#{n}" }
    sequence(:transcription_conventions) { |n| "transcription_conventions_#{n}" }
    sequence(:scribes_can_edit_titles) { true }
    sequence(:supports_translation) { true }
    sequence(:translation_instructions) { |n| "translation_instructions_#{n}" }
    sequence(:pages_are_meaningful) { true }
    sequence(:ocr_correction) { true }
    sequence(:slug) { |n| "slug_#{n}" }
    sequence(:picture) { |n| "picture_#{n}" }
    sequence(:featured_page) { |n| n }
    sequence(:identifier) { |n| "identifier_#{n}" }
  end
end
