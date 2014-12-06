class AddSourceTranslationToPage < ActiveRecord::Migration
  def change
    add_column :pages, :source_translation, :text
  end
end
