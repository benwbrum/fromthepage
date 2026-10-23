class AddHideNotesToCollections < ActiveRecord::Migration[7.0]
  def change
    add_column :collections, :hide_notes, :boolean, default: false
  end
end
