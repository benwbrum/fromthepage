class AddSupportsTranslationToWork < ActiveRecord::Migration[5.2]
  def change
    add_column :works, :supports_translation, :boolean, :default => false
  end
end
