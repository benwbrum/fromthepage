class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.boolean :add_as_owner, default: true
      t.boolean :add_as_collaborator, default: true
      t.boolean :note_added, default: true
      t.boolean :owner_stats, default: false
      t.boolean :user_activity, default: true
      t.column :user_id, :integer

      t.timestamps
    end
  end
end
