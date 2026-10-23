class CreateAiTranscriptionsTable < ActiveRecord::Migration[7.2]
  def up
    create_table :ai_transcriptions do |t|
      t.references :page, null: false, foreign_key: { on_delete: :cascade }, type: :integer
      t.text :source_text
      t.text :prompt
      t.string :model, null: false
      t.text :reasoning
      t.json :metadata, null: true

      t.timestamps
    end
  end

  def down
    drop_table :ai_transcriptions
  end
end
