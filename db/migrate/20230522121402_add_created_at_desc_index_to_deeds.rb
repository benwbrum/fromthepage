class AddCreatedAtDescIndexToDeeds < ActiveRecord::Migration[6.0]
  def up
    ActiveRecord::Base.connection.indexes('deeds').each do |index|
      remove_index 'deeds', name: index.name
    end

    add_index :deeds, [:created_at, :collection_id] , order: { created_at: :desc }
    add_index :deeds, :article_id
    add_index :deeds, [:collection_id, :created_at], order: { created_at: :desc }
    add_index :deeds, [:work_id, :created_at], order: { created_at: :desc }
    add_index :deeds, :page_id
    add_index :deeds, [:user_id, :created_at], order: { created_at: :desc }
    add_index :deeds, :note_id
    add_index :deeds, :visit_id
  end

  def down

  end
end
