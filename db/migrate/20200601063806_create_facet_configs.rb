class CreateFacetConfigs < ActiveRecord::Migration[5.0]
  def change
    create_table :facet_configs do |t|
      t.string :label
      t.string :input_type
      t.integer :order
      t.references :metadata_coverage, null: false, foreign_key: true

      t.timestamps
    end
  end
end
