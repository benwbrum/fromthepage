class AddDisambiguatorToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :disambiguator, :string
  end
end
