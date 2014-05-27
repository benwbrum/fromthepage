
class AddClientperfTables < ActiveRecord::Migration
  def self.up
    create_table :clientperf_uris do |t|
      t.string :uri
      t.timestamps
    end

    create_table :clientperf_results do |t|
      t.integer :clientperf_uri_id
      t.integer :milliseconds
      t.timestamps
    end
  end

  def self.down
    drop_table :clientperf_uris
    drop_table :clientperf_results
  end
end