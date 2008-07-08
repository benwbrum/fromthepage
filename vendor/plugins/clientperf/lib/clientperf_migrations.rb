class ClientperfMigrations
  MIGRATION_NAMES = %w(add_clientperf_tables add_clientperf_indexes)
  MIGRATION_CONTENTS = {
    :add_clientperf_tables => %(
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
end),
    :add_clientperf_indexes => %(
class AddClientperfIndexes < ActiveRecord::Migration
  def self.up
    add_index :clientperf_uris, :uri
    add_index :clientperf_results, :clientperf_uri_id
  end

  def self.down
    remove_index :clientperf_uris, :uri
    remove_index :clientperf_results, :clientperf_uri_id
  end
end)
  }
  
  class << self
    def install_new
      to_migrate = MIGRATION_NAMES.reject {|name| exists?(name) }
      to_migrate.each do |migration|
        generate(migration)
        install(migration)
      end
    end

    def generate(migration_name)
      Rails::Generator::Scripts::Generate.new.run(['migration', migration_name])
    end

    def migration_path(migration_name)
      Dir[File.join(RAILS_ROOT, 'db', 'migrate', "*_#{migration_name}.rb")].first
    end
    alias_method :exists?, :migration_path

    def install(migration)
      File.open(migration_path(migration), 'w') do |file|
        file << MIGRATION_CONTENTS[migration.to_sym]
      end
    end
  end
end