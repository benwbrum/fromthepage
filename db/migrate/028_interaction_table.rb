class InteractionTable < ActiveRecord::Migration
  def self.up
    create_table :interactions do |t|
      # application information
      t.column :user_id,    :integer
      t.column :collection_id,    :integer
      t.column :work_id,  :integer
      t.column :page_id,  :integer
      t.column :action,     :string, :limit => 20
      t.column :description,:string, :limit => 255
      t.column :params,     :string, :limit => 128
      # session information that should really be normalized out
      t.column :browser,    :string, :limit => 128
      t.column :session_id, :string, :limit => 40
      t.column :ip_address, :string, :limit => 16
      t.column :created_on, :datetime
    end

    add_index :interactions, :session_id
  end

  def self.down
    remove_index :interactions, :session_id
    drop_table :interactions
  end
end
