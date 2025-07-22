class DocumentSetsIndex < Chewy::Index
  include ChewyConcern

  index_name formatted_index_name('collection')
  default_import_options batch_size: 1000

  index_scope DocumentSet

  root _id: -> { "docset-#{id}" }
  field :is_public, type: 'boolean', value: -> { is_public }
  field :is_docset, type: 'boolean', value: -> { true }
  field :permissions_updated, type: 'long', ignore_blank: true, value: lambda {
    saved_change_to_visibility? ? Time.now.utc.to_i : nil
  }
  field :intro_block, type: 'text', analyzer: 'general', value: -> { description }
  field :language, type: 'keyword', value: -> { collection&.language }
  field :collection_id, type: 'integer'
  field :owner_user_id, type: 'integer'
  field :owner_display_name, type: 'text', value: -> { owner&.display_name }
  field :slug, type: 'text'

  field :title, type: 'text', analyzer: 'general' do
    field :no_underscores, type: 'text', analyzer: 'general_no_underscores'
  end
end
