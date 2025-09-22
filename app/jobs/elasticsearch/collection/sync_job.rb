class Elasticsearch::Collection::SyncJob < ApplicationJob
  queue_as :default

  def perform(user_id:, collection_id:, type: :collection, skip_collection: :true)
    collection = type == :collection ? Collection.find(collection_id) : DocumentSet.find(collection_id)

    CollectionsIndex.import collection unless skip_collection
    WorksIndex.import collection.works
    PagesIndex.import collection.pages
  end
end
