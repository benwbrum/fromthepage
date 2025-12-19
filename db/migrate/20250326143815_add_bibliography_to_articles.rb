class AddBibliographyToArticles < ActiveRecord::Migration[5.0]
  def change
    add_column :articles, :bibliography, :text, null: true
  end
end
