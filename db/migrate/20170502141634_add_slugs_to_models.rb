class AddSlugsToModels < ActiveRecord::Migration[5.2]
  def change
    #add slugs to collections
    add_column :collections, :slug, :string
    add_index :collections, :slug, unique: true
    #add slugs to document sets
    add_column :document_sets, :slug, :string
    add_index :document_sets, :slug, unique: true
    #add slugs to users
    add_column :users, :slug, :string
    add_index :users, :slug, unique: true
    #ad slugs to works
    add_column :works, :slug, :string
    add_index :works, :slug, unique: true


  end
end
