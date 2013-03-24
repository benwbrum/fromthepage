class AddPagesXmlTextIndexAgain < ActiveRecord::Migration
  def up
    add_index(:pages, :xml_text, :name => 'pages_xml_text_index', :length => 1000)
  end

  def down
  end
end
