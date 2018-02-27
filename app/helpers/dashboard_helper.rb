module DashboardHelper

  def collection_list(collection)
    @count = collection.works.count
    @works = collection.works.order(:title).limit(15)
  end

  def find_link_work(c)
    work = c.works.joins(:work_statistic).where.not(work_statistics: {complete: 100}).distinct.sample(1)
  end

  def owner_projects(owner)
    owner.all_owner_collections
  end

end