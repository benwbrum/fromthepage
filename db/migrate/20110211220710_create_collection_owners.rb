class CreateCollectionOwners < ActiveRecord::Migration
  def self.up
    create_table :collection_owners, :id => false  do |t|
      t.integer :user_id
      t.integer :collection_id
      t.timestamps
    end
  end

  def self.down
    drop_table :collection_owners
  end
end
