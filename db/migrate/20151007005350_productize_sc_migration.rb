class ProductizeScMigration < ActiveRecord::Migration[5.2]
  def change
    add_column    :sc_manifests, :at_id, :string
    add_column    :sc_manifests, :collection_id, :integer, index: true
  end
end
