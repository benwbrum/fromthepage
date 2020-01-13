
class AddClientperfIndexes < ActiveRecord::Migration[5.2]
  def self.up
    add_index :clientperf_uris, :uri
    add_index :clientperf_results, :clientperf_uri_id
  end

  def self.down
    remove_index :clientperf_uris, :uri
    remove_index :clientperf_results, :clientperf_uri_id
  end
end