# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def file_to_url(filename)
    filename.sub(/.*public/, "") 
  end

  # ripped off from
  # http://wiki.rubyonrails.org/rails/pages/CategoryTreeUsingActsAsTree
  def display_categories(categories, parent_id, &block)
    ret = "<ul>\n" 
      for category in categories
        if category.parent_id == parent_id
          ret << display_category(category, &block)
        end
      end
    ret << "</ul>\n" 
  end

  def display_category(category, &block)
    ret = "<li>\n" 
    ret << yield(category) 
    ret << display_categories(category.children, category.id, &block) if category.children.any?
    ret << "</li>\n" 
  end
end
