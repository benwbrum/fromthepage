class PagesAreFulltext < ActiveRecord::Migration
  def self.up
    # change the table type
    execute "ALTER TABLE pages ENGINE = MyISAM;"
    # create new index
    execute "CREATE FULLTEXT INDEX pages_xml_text_index ON pages (xml_text);"
  end

  def self.down
  end
end
