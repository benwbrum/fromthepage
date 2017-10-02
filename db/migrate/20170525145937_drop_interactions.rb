class DropInteractions < ActiveRecord::Migration
  def change
    drop_table :interactions if ActiveRecord::Base.connection.table_exists? 'interactions'
  end
end
