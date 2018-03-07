module DashboardHelper

  def collection_list(collection)
    @count = collection.works.count
    @works = collection.works.order(:title).limit(15)
  end

  def find_page(collection)
    page = Page.joins(:work).where(works: {collection_id: collection.id}).where(status: nil).sample(1).first
  end


  def owner_projects(owner)
    if params[:search]
      projects = @search_results.map {|col| col if col.owner_user_id == owner.id}.compact
    else
      sets = DocumentSet.unrestricted.where(owner_user_id: owner.id)
      collections = Collection.unrestricted.where(owner_user_id: owner.id)
      projects = (sets + collections).sort_by(&:pct_completed).first(3)
      #count = projects.count
      #unless count == 3
      #  projects = projects + owner.owned_collection_and_document_sets.sample(3-count)
      #end
      #@filtered = (projects.count - 3)
    end
    return projects
  end



end