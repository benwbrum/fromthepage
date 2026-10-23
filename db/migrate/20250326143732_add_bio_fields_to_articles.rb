class AddBioFieldsToArticles < ActiveRecord::Migration[5.0]
  def change
    add_column :articles, :birth_date, :string, null: true
    add_column :articles, :death_date, :string, null: true
    add_column :articles, :sex, :string, null: true
    add_column :articles, :race_description, :string, null: true
  end
end
