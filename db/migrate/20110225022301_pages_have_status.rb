class PagesHaveStatus < ActiveRecord::Migration
  def self.up  
    add_column :pages, :status, :string, :length => 10
    
    add_column :work_statistics, :blank_pages, :integer, :default => 0
    add_column :work_statistics, :incomplete_pages, :integer, :default => 0
  end

  def self.down
    remove_column :pages, :status

    remove_column :work_statistics, :blank_pages
    remove_column :work_statistics, :incomplete_pages
  end
end
