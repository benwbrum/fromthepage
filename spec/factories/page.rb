FactoryBot.define do
  factory :page do
    work { association(:work) }
    page_version { association(:page_version) }

    sequence(:title) { |n| "title_#{n}" }
    sequence(:source_text) { |n| "source_text_#{n}" }
    sequence(:base_image) { |n| "base_image_#{n}" }
    sequence(:base_width) { |n| n * 100 }
    sequence(:base_height) { |n| n  * 100}
    sequence(:shrink_factor) { 2 }
    sequence(:created_on) { |n| "created_on_#{n}" }
    sequence(:position) { |n| "position_#{n}" }
    sequence(:lock_version) { |n| "lock_version_#{n}" }
    sequence(:xml_text) { |n| "xml_text_#{n}" }
    sequence(:status) { |n| "status_#{n}" }
    # status { Page::STATUS_INDEXED }
    sequence(:source_translation) { |n| "source_translation_#{n}" }
    sequence(:xml_translation) { "<?xml version='1.0' encoding='UTF-8'?>    \n      <page>\n        <p/>\n      </page>\n" }
    sequence(:search_text) { |n| "search_text_#{n}" }
    sequence(:translation_status) { |n| Page::STATUS_TRANSLATED }
    sequence(:metadata) { |n| "metadata_#{n}" }
  end
end
