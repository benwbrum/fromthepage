class Elasticsearch::CleanOrphanedRecordsJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 1_000

  def perform
    records = [
      Collection.left_outer_joins(:owner).where('users.id IS NULL'),
      DocumentSet.left_outer_joins(:owner, :collection).where('users.id IS NULL OR collections.id IS NULL'),
      Work.left_outer_joins(:owner, :collection).where('users.id IS NULL OR collections.id IS NULL'),
      Page.left_outer_joins(:work).where('works.id IS NULL')
    ]

    records.each do |scope|
      scope.find_each(batch_size: BATCH_SIZE) do |item|
        item.handle_index_deletion
      end
    end
  end
end
