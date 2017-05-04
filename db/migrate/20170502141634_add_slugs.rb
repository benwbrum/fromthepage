class AddSlugs < ActiveRecord::Migration
  def change
    #add slugs to collections
    add_column :collections, :slug, :string
    add_index :collections, :slug, unique: true
    #add slugs to document sets
    add_column :document_sets, :slug, :string
    add_index :document_sets, :slug, unique: true

  end
end
