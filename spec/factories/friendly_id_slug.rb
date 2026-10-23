FactoryBot.define do
  factory :friendly_id_slug, class: 'FriendlyId::Slug' do
    sequence(:slug) { |n| "collection-slug-#{n}" }
    association :sluggable, factory: :collection
    sluggable_type { 'Collection' }
    scope { nil }
    created_at { Time.current }
    updated_at { Time.current }
  end
end
