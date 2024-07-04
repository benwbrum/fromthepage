class ProductizeScMigration < ActiveRecord::Migration[5.0]

  def change
    add_column    :sc_manifests, :at_id, :string
    add_column    :sc_manifests, :collection_id, :integer
    add_index :sc_manifests, :collection_id
  end

end
