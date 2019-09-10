module DashboardHelper

  def collection_list(collection)
    @count = collection.works.count
    @works = collection.works.order(:title).limit(15)
  end

end