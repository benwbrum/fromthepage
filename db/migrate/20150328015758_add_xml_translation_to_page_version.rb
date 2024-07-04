class AddXmlTranslationToPageVersion < ActiveRecord::Migration[5.0]

  def change
    add_column :page_versions, :xml_translation, :text
  end

end
