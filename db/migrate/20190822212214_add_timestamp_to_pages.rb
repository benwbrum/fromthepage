class AddTimestampToPages < ActiveRecord::Migration
  def change
    add_column :pages, :edit_started_at, :timestamp
  end
end
