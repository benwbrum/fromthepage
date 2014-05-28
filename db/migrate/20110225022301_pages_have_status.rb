class PagesHaveStatus < ActiveRecord::Migration
  def self.up
    unless Page.columns_hash['status']
      add_column :pages, :status, :string, :length => 10
    end


    add_column :work_statistics, :blank_pages, :integer, :default => 0, :force => true
    add_column :work_statistics, :incomplete_pages, :integer, :default => 0, :force => true
  end

  def self.down
    remove_column :pages, :status

    remove_column :work_statistics, :blank_pages
    remove_column :work_statistics, :incomplete_pages
  end
end
