class Elasticsearch::Collection::SyncJob < ApplicationJob
  queue_as :default

  def perform(user_id:, collection_id:, type: :collection, skip_collection: :true)
    if type == :collection
      collection = Collection.find(collection_id)

      CollectionsIndex.import collection unless skip_collection
    else
      collection = DocumentSet.find(collection_id)

      if !skip_collection
        CollectionsIndex.import collection.collection
        DocumentSetsIndex.import collection
      end
    end

    WorksIndex.import collection.works
    PagesIndex.import collection.pages
  end
end
