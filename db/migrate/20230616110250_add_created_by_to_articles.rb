class AddCreatedByToArticles < ActiveRecord::Migration[6.0]
  def change
    add_column :articles, :created_by_id, :integer, index: true
    add_foreign_key :articles, :users, column: :created_by_id
  end
end
