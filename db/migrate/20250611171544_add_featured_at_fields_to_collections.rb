class AddFeaturedAtFieldsToCollections < ActiveRecord::Migration[6.1]
  def up
    add_column :collections, :featured_at, :datetime, null: true
    add_column :document_sets, :featured_at, :datetime, null: true
  end

  def down
    remove_column :collections, :featured_at
    remove_column :document_sets, :featured_at
  end
end
