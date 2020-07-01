class CreateOntologies < ActiveRecord::Migration
  def change
    create_table :ontologies do |t|
      t.string :name
      t.string :description
      t.string :domainkey
      t.string :url
      t.timestamps null: false
    end
  end
end
