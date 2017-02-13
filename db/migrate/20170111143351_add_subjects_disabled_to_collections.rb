class AddSubjectsDisabledToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :subjects_disabled, :boolean, default: false
  end
end
