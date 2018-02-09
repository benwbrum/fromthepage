class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.boolean :work_added, default: true
      t.boolean :add_as_owner, default: true
      t.boolean :add_as_collaborator, default: true
      t.boolean :page_edited, default: true
      t.boolean :note_added, default: true
      t.boolean :owner_stats, default: false
      t.column :user_id, :integer

      t.timestamps
    end
  end
end
