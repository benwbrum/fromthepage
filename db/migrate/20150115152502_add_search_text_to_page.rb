class AddSearchTextToPage < ActiveRecord::Migration
  def self.up
    add_column :pages, :search_text, :text unless Page.column_names.include? 'search_text'

    Page.all.each do |page|
      page.populate_search
      # the following looks odd, but we want to skip the callbacks which are
      # usually fired by page.save! since we don't want phantom page versions
      # or deeds or interactions
      page.update_columns({:search_text => page.search_text}) 
    end
    # create new index
    execute "CREATE FULLTEXT INDEX pages_search_text_index ON pages (search_text);"
  end

  def self.down
    execute "DROP INDEX pages_xml_text_index ON pages;"
    drop_column :pages, :search_text
  end

end
