class UpdatePagesCachedAiStatus < ActiveRecord::Migration[7.2]
  BATCH_SIZE = 10_000

  def up
    Page.includes(:ai_transcription).find_in_batches(batch_size: BATCH_SIZE) do |pages|
      updates = pages.filter_map do |page|
        next unless page.ai_transcription

        page.cached_ai_status = page.ai_transcription.status
        page
      end

      Page.import!(
        updates,
        on_duplicate_key_update: [:cached_ai_status]
      )
    end
  end

  def down
  end
end
