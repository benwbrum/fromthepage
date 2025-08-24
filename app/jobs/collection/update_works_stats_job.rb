class Collection::UpdateWorksStatsJob < ApplicationJob
  queue_as :default

  def perform(collection_id:)
    collection = Collection.find(collection_id)

    works = collection.works.includes(:work_statistic)
    works_stats = collection.get_works_stats_hash(works.ids)
    works.each do |w|
      w.work_statistic.recalculate_from_hash(works_stats[w.id])
    end
    collection.calculate_complete
  end
end
