class RemovePagesXmlTextIndexAgain < ActiveRecord::Migration[5.0]

  def up
    remove_index :pages, name: :pages_xml_text_index
  end

  def down
  end

end
