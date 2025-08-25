class ArticlesIndex < Chewy::Index
  include ChewyConcern

  index_name formatted_index_name('article')
  default_import_options batch_size: 1000

  index_scope Article

  field :db_id, type: 'integer', value: -> { id }
  field :collection_id, type: 'integer'
  field :docset_id, type: 'integer', value: -> { works.flat_map(&:document_sets).pluck(:id) }
  field :category_ids, type: 'integer', value: -> { categories.map(&:id) }
  field :owner_user_id, type: 'integer', value: -> { created_by_id }
  field :is_public, type: 'boolean', value: -> {
    !collection&.restricted ||
      works.flat_map(&:document_sets).any? { |doc_set| [ 'public', 'read_only' ].include?(doc_set.visibility) }
  }

  field :title, type: 'text', analyzer: 'general' do
    field :no_underscores, type: 'text', analyzer: 'general_no_underscores'
  end

  field :content_english, type: 'text', analyzer: 'text_english', value: -> { source_text }
end
