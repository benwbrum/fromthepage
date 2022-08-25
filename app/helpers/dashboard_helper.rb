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

  # makes an intro block into a snippet by removing style tag, stripping tags, and truncating
  def to_snippet(intro_block)
    # remove style tag, Loofah.fragment.text doesn't do this (strip_tags does)
    doc = Nokogiri::HTML(intro_block)
    doc.xpath('//style').each { |n| n.remove } 
    # strip tags and truncate
    truncate(Loofah.fragment(doc.to_s).text(encode_special_chars: false), length: 300, separator: ' ') || '' 
  end
end
