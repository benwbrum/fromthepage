class AddSupportsTranslationToWork < ActiveRecord::Migration[5.0]
  def change
    add_column :works, :supports_translation, :boolean, default: false
  end
end
