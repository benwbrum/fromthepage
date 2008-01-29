class CreateCollection < ActiveRecord::Migration
  def self.up
    # collection table
    create_table :collections do |t|
      t.column :title, :string, :limit => 255
      t.column :owner_user_id, :integer
      t.column :created_on, :datetime
    end
    # work fk
    add_column :works, :collection_id, :integer
    # article fk
    add_column :articles, :collection_id, :integer
  end

  def self.down
    # collection table
    drop_table :collections
    # work fk
    remove_column :works, :collection_id
    # article fk
    remove_column :articles, :collection_id
  end
end
