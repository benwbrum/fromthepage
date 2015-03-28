class AddSourceTranslationToPageVersion < ActiveRecord::Migration

  def change
    add_column :page_versions, :source_translation, :text
  end
end
