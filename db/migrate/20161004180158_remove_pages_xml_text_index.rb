class RemovePagesXmlTextIndex < ActiveRecord::Migration[5.0]
  def change
    remove_index :pages, name: :pages_xml_text_index if index_exists?(:pages, :xml_text, name: "pages_xml_text_index")
  end
end
