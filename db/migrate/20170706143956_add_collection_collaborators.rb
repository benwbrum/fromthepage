class AddCollectionCollaborators < ActiveRecord::Migration[5.2]
  def self.up
    create_table :collection_collaborators, :id => false  do |t|
      t.integer :user_id
      t.integer :collection_id
    end
  end


  def self.down
    drop_table :collection_collaborators
  end
end
