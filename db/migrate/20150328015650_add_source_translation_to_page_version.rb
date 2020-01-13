class AddSourceTranslationToPageVersion < ActiveRecord::Migration[5.2]

  def change
    add_column :page_versions, :source_translation, :text
  end
end
