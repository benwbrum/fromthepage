class CreateOaiRepositories < ActiveRecord::Migration[5.2]
  def self.up
    create_table :oai_repositories do |t|
      t.string :url
      t.timestamps
    end
  end

  def self.down
    drop_table :oai_repositories
  end
end
