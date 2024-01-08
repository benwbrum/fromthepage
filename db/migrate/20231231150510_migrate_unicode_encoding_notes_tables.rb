class MigrateUnicodeEncodingNotesTables < ActiveRecord::Migration[6.0]
  def change
    execute "ALTER TABLE notes CHANGE body body mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  end
end
