class AddUniqueIndexToArticlesCollectionAndTitle < ActiveRecord::Migration[7.2]
  INDEX_NAME = 'index_articles_on_collection_id_and_title_unique'

  def up
    reconcile_duplicate_titles!
    add_index :articles, [:collection_id, :title], unique: true, name: INDEX_NAME
  end

  def down
    remove_index :articles, name: INDEX_NAME
  end

  private

  # articles.title uses utf8mb3_general_ci, so grouping by title here has the
  # same case-insensitive (and trailing-space-insensitive) semantics as the
  # index. We deliberately do not trim or otherwise normalize whitespace:
  # leading and internal whitespace remain meaningful, while MySQL's collation
  # treats trailing spaces as equivalent. Existing collisions are retained and
  # given an explicit, deterministic suffix rather than deleting subjects and
  # risking the loss of their links, categories, or revision history.
  def reconcile_duplicate_titles!
    duplicate_ids = select_values(<<~SQL)
      SELECT DISTINCT duplicate.id
        FROM articles duplicate
        JOIN articles keeper
          ON keeper.collection_id = duplicate.collection_id
         AND keeper.title = duplicate.title
         AND keeper.id < duplicate.id
    SQL

    duplicate_ids.each do |id|
      title = select_value("SELECT title FROM articles WHERE id = #{connection.quote(id)}")
      suffix = " [duplicate #{id}]"
      reconciled_title = "#{title.to_s[0, 255 - suffix.length]}#{suffix}"

      # An earlier manual reconciliation may already use our preferred title.
      # Keep the suffix deterministic but make room for a counter if necessary.
      counter = 2
      while select_value(<<~SQL).present?
        SELECT id FROM articles
         WHERE collection_id = (SELECT collection_id FROM articles WHERE id = #{connection.quote(id)})
           AND title = #{connection.quote(reconciled_title)}
           AND id <> #{connection.quote(id)}
         LIMIT 1
      SQL
        suffix = " [duplicate #{id}-#{counter}]"
        reconciled_title = "#{title.to_s[0, 255 - suffix.length]}#{suffix}"
        counter += 1
      end

      execute <<~SQL
        UPDATE articles
           SET title = #{connection.quote(reconciled_title)}
         WHERE id = #{connection.quote(id)}
      SQL
    end
  end
end
