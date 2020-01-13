class ProductizeScCollection < ActiveRecord::Migration[5.2]
  def change
    add_column    :sc_collections, :at_id, :string
    add_column    :sc_collections, :parent_id, :integer
    add_column    :sc_collections, :label, :string
    remove_column :sc_collections, :context

  end
end
