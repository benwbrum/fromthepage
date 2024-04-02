class MigrateUnicodeEncoding < ActiveRecord::Migration[6.0]
  def change
    p Time.now
    execute "ALTER TABLE pages CHANGE source_text source_text mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    execute "ALTER TABLE pages CHANGE xml_text xml_text mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    execute "ALTER TABLE pages CHANGE source_translation source_translation mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    execute "ALTER TABLE pages CHANGE xml_translation xml_translation mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    execute "ALTER TABLE pages CHANGE search_text search_text text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    p Time.now
    execute "ALTER TABLE page_versions CHANGE transcription transcription mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    execute "ALTER TABLE page_versions CHANGE xml_transcription xml_transcription mediumtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    execute "ALTER TABLE page_versions CHANGE source_translation source_translation text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    execute "ALTER TABLE page_versions CHANGE xml_translation xml_translation text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

  end
end
