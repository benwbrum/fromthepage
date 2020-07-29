class CreateScCollections < ActiveRecord::Migration[5.0]
  def change
    create_table :sc_collections do |t|
      t.references :collection, index: true
      t.string :context

      t.timestamps
    end
  end
end
