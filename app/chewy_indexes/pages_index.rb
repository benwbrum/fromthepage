class PagesIndex < Chewy::Index
  include ChewyConcern

  index_name formatted_index_name('page')
  default_import_options batch_size: 1000

  index_scope Page

  field :db_id, type: 'integer', value: -> { id }
  field :is_public, type: 'boolean', value: -> { !collection&.restricted || work&.document_sets&.unrestricted&.any? }
  field :collection_id, type: 'integer', value: -> { work&.collection&.id }
  field :docset_id, type: 'integer', value: -> { work&.document_sets&.pluck(:id) }
  field :owner_user_id, type: 'integer', value: -> { collection&.owner_user_id }
  field :work_id, type: 'integer', value: -> { work&.id }

  field :search_text, type: 'text', analyzer: 'general'
  field :source_text, type: 'text', analyzer: 'general'
  field :source_translation, type: 'text'

  field :content_english, type: 'text', analyzer: 'text_english', value: -> { source_text }

  field :title, type: 'text', analyzer: 'general' do
    field :no_underscores, type: 'text', analyzer: 'general_no_underscores'
  end

  # These fields are declared in elastic schema
  # but not currently being set in as_indexed_json
  field :canonical_entities, type: 'text', ignore_blank: true, value: -> { nil }
  field :entity_names, type: 'text', ignore_blank: true, value: -> { nil }
  field :language, type: 'keyword', ignore_blank: true, value: -> { nil }
end
