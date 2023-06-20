class CreateCollectionBlocks < ActiveRecord::Migration[6.0]
  def change
    create_table :collection_blocks do |t|
      t.integer :collection_id, null: false
      t.integer :user_id, null: false

      t.timestamps
    end

    add_foreign_key :collection_blocks, :collections, column: :collection_id, primary_key: :id
    add_foreign_key :collection_blocks, :users, column: :user_id, primary_key: :id
    add_index :collection_blocks, [:collection_id, :user_id], unique: true
  end

  def down
    remove_index :collection_blocks, [:collection_id, :user_id]
    remove_foreign_key :collection_blocks, :collections
    change_column :collection_blocks, :collection_id, :bigint
    remove_foreign_key :collection_blocks, :users
    change_column :collection_blocks, :user_id, :bigint
    drop_table :collection_blocks
  end
end
