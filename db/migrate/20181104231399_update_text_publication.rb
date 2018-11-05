class UpdateTextPublication < ActiveRecord::Migration
  def change
    change_column :publications, :text, :text
  end
end
