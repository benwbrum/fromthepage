class ConvertPagesToInnoDb < ActiveRecord::Migration[5.0]
  def up
    # Recreate full-text index on search_text column
    execute 'ALTER TABLE pages DROP INDEX pages_search_text_index;'

    # Convert table engine to InnoDB
    execute 'ALTER TABLE pages ENGINE=InnoDB;'

    # Recreate full-text index on search_text column
    execute 'ALTER TABLE pages ADD FULLTEXT pages_search_text_index (search_text);'
  end

  def down
    # Recreate full-text index on search_text column
    execute 'ALTER TABLE pages DROP INDEX pages_search_text_index;'

    # Convert table engine back to MyISAM
    execute 'ALTER TABLE pages ENGINE=MyISAM;'

    # Recreate full-text index on search_text column
    execute 'ALTER TABLE pages ADD FULLTEXT pages_search_text_index (search_text);'
  end
end