class CreateOaiSets < ActiveRecord::Migration[5.2]
  def self.up
    create_table :oai_sets do |t|
      t.string :set_spec
      t.string :repository_url
      t.integer :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :oai_sets
  end
end
