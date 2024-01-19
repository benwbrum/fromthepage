class AddPagesCountToArticles < ActiveRecord::Migration[6.0]
  def up
    add_column :articles, :pages_count, :integer, default: 0

    # Update the pages_count for existing records
    Article.reset_column_information
    Article.find_each do |article|
      Article.update_counters(article.id, pages_count: article.pages.length)
    end
  end

  def down
    remove_column :articles, :pages_count
  end
end
