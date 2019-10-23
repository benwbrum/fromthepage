class AddSubjectsDisabledToCollections < ActiveRecord::Migration[5.2]
  def change
    add_column :collections, :subjects_disabled, :boolean, default: false
  end
end
