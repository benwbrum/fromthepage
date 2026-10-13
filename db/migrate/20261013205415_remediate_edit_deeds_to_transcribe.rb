class RemediateEditDeedsToTranscribe < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  BATCH_SIZE = 1_000

  def up
    Page.in_batches(of: BATCH_SIZE) do |batch|
      page_ids = batch.pluck(:id)

      eligible_page_ids = Page.where(id: page_ids)
                              .where(
                                Deed.where('deeds.page_id = pages.id')
                                    .where(deed_type: DeedType::PAGE_EDIT)
                                    .arel.exists
                              )
                              .where.not(
                                Deed.where('deeds.page_id = pages.id')
                                    .where(deed_type: DeedType::PAGE_TRANSCRIPTION)
                                    .arel.exists
                              )
                              .pluck(:id)

      next if eligible_page_ids.empty?

      earliest_deed_ids = Deed
        .where(page_id: eligible_page_ids, deed_type: DeedType::PAGE_EDIT)
        .where(
          "(page_id, created_at) IN (
          SELECT page_id, MIN(created_at)
          FROM deeds
          WHERE page_id IN (?) AND deed_type = ?
          GROUP BY page_id
          )",
          eligible_page_ids,
          DeedType::PAGE_EDIT
        )
        .pluck(:id)

      Deed.where(id: earliest_deed_ids).update_all(deed_type: DeedType::PAGE_TRANSCRIPTION)

      sleep(0.02)
    end
  end

  def down
    # NO-OP
  end
end
