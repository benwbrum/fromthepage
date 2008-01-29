class ReviewHack < ActiveRecord::Migration
  def self.up
    add_column :comments, :comment_type, :string, :limit => 10, :default => 'annotation'
    add_column :comments, :comment_status, :string, :limit => 10, :default => 'new'
  end

  def self.down
    remove_column :comments, :type
    remove_column :comments, :type_status
  end
end
