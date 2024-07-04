class RemoveForeignKeyFromArticles < ActiveRecord::Migration[6.0]

  def change
    remove_foreign_key :articles, :users, column: :created_by_id
  end

end
