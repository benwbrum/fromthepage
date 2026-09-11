class ChangeSearchTextToMediumtext < ActiveRecord::Migration[7.2]
  def up
    execute "ALTER TABLE pages CHANGE search_text search_text mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  end

  def down
    execute "ALTER TABLE pages CHANGE search_text search_text text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  end
end
