module DashboardHelper

  def collection_list(collection)
    @count = collection.works.count
    @works = collection.works.order(:title).limit(15)
  end

  def recent_deeds
    limited = Deed.joins(:collection).where('collections.restricted = 0')
    deeds = limited.includes(:page, :user, collection: [:works]).order('deeds.created_at DESC').limit(20)

    render({ :partial => 'deed/deeds', :locals => { :limit => 20, :deeds => deeds, :options => {} } })
  end

end