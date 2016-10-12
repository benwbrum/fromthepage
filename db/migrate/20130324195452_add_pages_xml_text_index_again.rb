class AddPagesXmlTextIndexAgain < ActiveRecord::Migration
  def up
    #this index is no longer used; now search_text is the relevant column
#    add_index(:pages, :xml_text, :name => 'pages_xml_text_index', :length => 1000)
  end

  def down
  end
end
