class AddXmlTranslationToPageVersion < ActiveRecord::Migration
  def change
    add_column :page_versions, :xml_translation, :text
  end
end
