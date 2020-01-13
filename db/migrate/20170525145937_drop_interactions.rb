class DropInteractions < ActiveRecord::Migration[5.2]
  def change
    drop_table :interactions if ActiveRecord::Base.connection.table_exists? 'interactions'
  end
end
