class AddVersionToScCollection < ActiveRecord::Migration[6.0]
  def change
    add_column :sc_collections, :version, :string, default: "2"
  end
end
