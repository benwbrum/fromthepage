module DashboardHelper

  def collection_list(collection)
    @count = collection.works.count
    @works = collection.works.order(:title).limit(15)
  end

  def find_page(collection)
    page = Page.joins(:work).where(works: {collection_id: collection.id}).where(works: {restrict_scribes: false}).where(status: nil).sample(1).first
  end

  def owner_projects(owner)
    if params[:search]
      projects = @search_results.map {|col| col if col.owner_user_id == owner.id}.compact
    else
      sets = DocumentSet.unrestricted.where(owner_user_id: owner.id).where.not(pct_completed: 90..100).where.not(description: [nil, '']).select {|set| set.works.exists? }
      collections = Collection.unrestricted.where(owner_user_id: owner.id).where.not(pct_completed: 90..100).where.not(intro_block: [nil, '']).select {|c| c.works.exists? }
      projects = (sets + collections).sample(3)
    end
    return projects
  end



end