class WorksIndex < Chewy::Index
  include ChewyConcern

  index_name formatted_index_name('work')
  default_import_options batch_size: 1000

  index_scope Work

  field :db_id, type: 'integer', value: -> { id }
  field :is_public, type: 'boolean', value: -> { !collection&.restricted || document_sets&.unrestricted&.any? }
  field :permissions_updated, type: 'long', ignore_blank: true, value: -> { nil }
  field :collection_id, type: 'integer'
  field :docset_id, type: 'integer', value: -> { document_sets&.pluck(:id) }
  field :owner_user_id, type: 'integer', value: -> { collection&.owner_user_id }

  field :searchable_metadata, type: 'text' do
    field :identifier_whitespace, type: 'text', analyzer: 'identifier_whitespace', search_analyzer: 'identifier_whitespace_querytime'
    field :whitespace, type: 'text', analyzer: 'general_whitespace'
  end

  field :title, type: 'text', analyzer: 'general' do
    field :no_underscores, type: 'text', analyzer: 'general_no_underscores'
  end
end
