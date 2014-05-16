class CreateArticlesCategories < ActiveRecord::Migration
  def self.up

    create_table :articles_categories, :id => false do |t|
      # foreign key to articles
      t.column :article_id, :integer
      # foreign key to categories
      t.column :category_id, :integer
    end
  end

  def self.down
    drop_table :articles_categories
  end
end
