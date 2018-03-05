module DashboardHelper

  def collection_list(collection)
    @count = collection.works.count
    @works = collection.works.order(:title).limit(15)
  end

  def find_owner(id)
    owner = User.find_by(id: id)
    return owner
  end

  def owner_projects(owner)
    if params[:search]
      results = @search_results.map {|col| col if col.owner_user_id == owner.id}
    end
    return results
  end



end