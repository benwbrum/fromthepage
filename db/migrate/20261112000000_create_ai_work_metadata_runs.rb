# Tracks the AI metadata drafting flow on the collection AI settings tab:
# a reviewed sample, then the remaining works drafted with the reviewed
# sample works as prompt examples (or every work, when the sample is skipped).
class CreateAiWorkMetadataRuns < ActiveRecord::Migration[7.2]
  def change
    create_table :ai_work_metadata_runs do |t|
      t.references :collection, type: :integer, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, type: :integer, foreign_key: { on_delete: :nullify }
      t.string :kind, null: false
      t.text :example_work_ids
      t.timestamps
    end

    change_table :ai_work_metadata, bulk: true do |t|
      t.references :ai_work_metadata_run, foreign_key: { on_delete: :nullify }
      t.datetime :reviewed_at
    end

    # Nullable and unindexed so it can be added instantly to a large table.
    # Marks pages transcribed inside an AI metadata draft job.
    add_column :ai_transcriptions, :ai_work_metadata_id, :bigint
  end
end
