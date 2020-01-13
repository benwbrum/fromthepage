class IaWorkHasFormat < ActiveRecord::Migration[5.2]
  def self.up
    add_column :ia_works, :image_format, :string, :length => 10, :default => 'jp2'
    add_column :ia_works, :archive_format, :string, :length => 10, :default => 'zip'
  end

  def self.down
    remove_column :ia_works, :image_format
    remove_column :ia_works, :archive_format
  end
end
