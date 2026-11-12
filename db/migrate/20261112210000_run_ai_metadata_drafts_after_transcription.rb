# AI metadata drafting now waits for the collection's AI transcription to finish before
# choosing the sample or drafting, instead of transcribing pages inside each draft job.
# started_at is set once the run's drafts have been queued; until then it is waiting.
class RunAiMetadataDraftsAfterTranscription < ActiveRecord::Migration[7.2]
  def change
    add_column :ai_work_metadata_runs, :started_at, :datetime
    remove_column :ai_transcriptions, :ai_work_metadata_id, :bigint
  end
end
