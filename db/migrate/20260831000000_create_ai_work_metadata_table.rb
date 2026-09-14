class CreateAiWorkMetadataTable < ActiveRecord::Migration[7.2]
  def up
    create_table :ai_work_metadata do |t|
      t.references :work, null: false, foreign_key: { on_delete: :cascade }, type: :integer
      t.text :metadata_json
      t.text :prompt
      t.string :model, null: false
      t.text :reasoning
      t.json :metadata, null: true
      t.string :status, default: 'new'

      t.timestamps
    end

    add_index :ai_work_metadata, :status
  end

  def down
    drop_table :ai_work_metadata
  end
end
