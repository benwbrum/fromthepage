class CollectionsIndex < Chewy::Index
  include ChewyConcern

  index_name formatted_index_name('collection')
  default_import_options batch_size: 1000

  index_scope Collection

  field :is_public, type: 'boolean', value: -> { !restricted }
  field :is_docset, type: 'boolean', value: -> { false }
  field :permissions_updated, type: 'long', ignore_blank: true, value: lambda {
    saved_change_to_restricted? ? Time.now.utc.to_i : nil
  }
  field :intro_block, type: 'text', analyzer: 'general'
  field :language, type: 'keyword'
  field :collection_id, type: 'integer', ignore_blank: true, value: -> { nil }
  field :owner_user_id, type: 'integer'
  field :owner_display_name, type: 'text', value: -> { owner&.display_name }
  field :slug, type: 'text'

  field :title, type: 'text', analyzer: 'general' do
    field :no_underscores, type: 'text', analyzer: 'general_no_underscores'
  end
end
