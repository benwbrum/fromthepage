class AddXmlTranslationToPage < ActiveRecord::Migration[5.0]

  def change
    add_column :pages, :xml_translation, :text
  end

end
