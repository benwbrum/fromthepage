module DashboardHelper
  def collection_list(collection)
    @count = collection.works.count
    @works = collection.works.order(:title).limit(15)
  end

  def dashboard_set_title
    case
    when is_active_link?(dashboard_startproject_path)
      content_for :page_title, "Start A Project - Owner Dashboard"
    when is_active_link?(dashboard_owner_path)
      content_for :page_title, "Your Works - Owner Dashboard"
    when is_active_link?(dashboard_summary_path)
      content_for :page_title, "Summary - Owner Dashboard"
    end
  end
end
