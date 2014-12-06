class AddSupportsTranslationToWork < ActiveRecord::Migration
  def change
    add_column :works, :supports_translation, :boolean, :default => false
  end
end
