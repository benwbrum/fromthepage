class AddIndexToArticleCategories < ActiveRecord::Migration[5.0]

  def change
    add_index :articles_categories, [:article_id, :category_id]
  end

end
