class CreateTranscribeAuthorizations < ActiveRecord::Migration
  def self.up
    create_table :transcribe_authorizations, :id => false  do |t|
      # t.column :name, :string
      t.column :user_id, :integer
      t.column :work_id, :integer
    end

    add_column :works, :owner_user_id, :integer
  end

  def self.down
    drop_table :transcribe_authorizations

    remove_column :works, :owner_user_id
  end
end
