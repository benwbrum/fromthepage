class IaWorkHasFilenames < ActiveRecord::Migration
  def self.up
    add_column :ia_works, :scandata_file, :string, :length => 100
    add_column :ia_works, :djvu_file, :string, :length => 100
    add_column :ia_works, :zip_file, :string, :length => 100
  end

  def self.down
    drop_column :ia_works, :scandata_file
    drop_column :ia_works, :djvu_file
    drop_column :ia_works, :zip_file
  end
end
