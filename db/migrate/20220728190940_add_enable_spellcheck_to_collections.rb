class AddEnableSpellcheckToCollections < ActiveRecord::Migration[6.0]

  def change
    add_column :collections, :enable_spellcheck, :boolean, default: false
  end

end
