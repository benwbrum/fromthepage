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

    WorksIndex.import collection.works.includes({ collection: :owner }, :document_sets)
    PagesIndex.import collection.pages.includes(work: [{ collection: :owner }, :document_sets])
    ArticlesIndex.import collection.articles.includes(:collection, :categories, { works: :document_sets })
  end
end
