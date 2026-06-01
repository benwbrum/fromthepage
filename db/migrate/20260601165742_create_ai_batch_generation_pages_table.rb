class CreateAiBatchGenerationPagesTable < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_batch_generation_pages do |t|
      t.references :ai_batch_generation, null: false, foreign_key: true, type: :integer
      t.references :page, null: false, foreign_key: true, type: :integer
      t.references :ai_transcription, foreign_key: true

      t.timestamps
    end
  end
end
