module DashboardHelper

  def collection_list(collection)
    @count = collection.works.count
    @works = collection.works.order(:title).limit(15)
  end

  def owner_projects(owner)
    if params[:search]
      col_ids = @search_results.map {|col| col.id if col.owner_user_id == owner.id}
    end

    all_projects = owner.all_owner_collections.unrestricted 
    projects = owner.all_owner_collections.unrestricted.joins(:works).merge(Work.incomplete_transcription).distinct.sample(3)
    @filtered = all_projects.count - projects.count
    return projects
  end

end