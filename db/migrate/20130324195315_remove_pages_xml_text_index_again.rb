class RemovePagesXmlTextIndexAgain < ActiveRecord::Migration
  def up
    remove_index :pages, :name => :pages_xml_text_index
  end

  def down
  end
end
