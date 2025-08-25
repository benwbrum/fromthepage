class Elasticsearch::Collection::SyncJob < ApplicationJob
  queue_as :default

  def perform(user_id:, collection_id:, type: :collection)
    collection = type == :collection ? Collection.find(collection_id) : DocumentSet.find(collection_id)

    WorksIndex.import collection.works.includes({ collection: :owner }, :document_sets)
    PagesIndex.import collection.pages.includes(work: [{ collection: :owner }, :document_sets])
    ArticlesIndex.import collection.articles.includes(:collection, :categories, { works: :document_sets })
  end
end
