module DashboardHelper

  def collection_list(collection)
    @count = collection.works.count
    @works = collection.works.order(:title).limit(15)
  end

  def find_link_work(c)
    work = c.works.joins(:work_statistic).where.not(work_statistics: {complete: 100}).distinct.sample(1).first
    link = collection_read_work_path(work.collection.owner, work.collection, work)
  end

  def owner_projects(owner)
    all_projects = owner.all_owner_collections.unrestricted 
    projects = owner.all_owner_collections.unrestricted.joins(works: :work_statistic).where.not(work_statistics: {complete: 100}).distinct.sample(3)
    @filtered = all_projects.count - projects.count
    return projects
  end

end