class AddFooterBlockToUsers < ActiveRecord::Migration[6.0]
  def self.up
    add_column :users, :footer_block, :text, size: :medium
  end

  def self.down
    remove_column :users, :footer_block
  end
end
