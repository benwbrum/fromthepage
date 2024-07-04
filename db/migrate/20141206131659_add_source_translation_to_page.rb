class AddSourceTranslationToPage < ActiveRecord::Migration[5.0]

  def change
    add_column :pages, :source_translation, :text
  end

end
