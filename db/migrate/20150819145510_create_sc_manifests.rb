class CreateScManifests < ActiveRecord::Migration
  def change
    create_table :sc_manifests do |t|
      t.references :work, index: true
      t.references :sc_collection, index: true
      t.string :sc_id
      t.string :label
      t.text :metadata
      t.string :first_sequence_id
      t.string :first_sequence_label

      t.timestamps
    end
  end
end
