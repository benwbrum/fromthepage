class AddOrgFieldsToArticles < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :begun, :string
    add_column :articles, :ended, :string
  end
end
