class UsersIndex < Chewy::Index
  include ChewyConcern

  index_name formatted_index_name('user')
  default_import_options batch_size: 1000

  index_scope User

  field :db_id, type: 'integer', value: -> { id }
  field :about, type: 'text', analyzer: 'general'
  field :display_name, type: 'keyword', value: -> { display_name } do
    field :text, type: 'text'
  end
  field :login, type: 'keyword' do
    field :text, type: 'text'
  end
  field :real_name, type: 'keyword' do
    field :text, type: 'text'
  end
  field :website, type: 'keyword' do
    field :text, type: 'text'
  end
end
