class AddXmlTranslationToPage < ActiveRecord::Migration
  def change
    add_column :pages, :xml_translation, :text
  end
end
