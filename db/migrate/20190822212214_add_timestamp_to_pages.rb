class AddTimestampToPages < ActiveRecord::Migration[5.0]

  def change
    add_column :pages, :edit_started_at, :timestamp
  end

end
