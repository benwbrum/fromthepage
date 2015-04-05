module ApplicationHelper

  def html_block(tag)
    render({ :partial => 'page_block/html_block',
             :locals =>
              { :tag => tag,
                :page_block => @html_blocks[tag],
                :origin_controller => controller_name,
                :origin_action => action_name
              }
          })
  end

  def file_to_url(filename)
    if filename
      filename.sub(/.*public/, "")
    else
      ""
    end
  end

  def svg_symbol(id, options={})
    content_tag(:svg, options) do
      content_tag(:use, nil, :'xlink:href' => asset_path('symbols.svg') + id)
    end
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

  def deeds_for(options={})
    limit = options[:limit] || 20

    condition = [String.new]

    if options[:types]
      types = options[:types]
      types = types.map { |t| "'#{t}'"}
      condition[0] = "deed_type IN (#{types.join(',')})"
    end

    if options[:user_id]
      condition[0] << " AND " unless condition[0].length == 0
      condition[0] << "user_id = ?"
      condition << options[:user_id]
    end

    if options[:not_user_id]
      condition[0] << " AND " unless condition[0].length == 0
      condition[0] << "user_id != ?"
      condition << options[:not_user_id]
    end

    if options[:collection]
      deeds = @collection.deeds.where(condition).order('created_at DESC').limit(limit)
    else
      condition[0] << " AND " unless condition[0].length == 0
      condition[0] << "collections.restricted = 0"
      deeds = Deed.includes(:collection).where(condition).order('created_at DESC').limit(limit).references(:collection)
    end

    render({ :partial => 'deed/deeds', :locals => { :limit => limit, :deeds => deeds, :options => options } })
  end

  def time_ago(time)
    delta_seconds = (Time.new - time).floor
    delta_minutes = (delta_seconds / 60).floor
    delta_hours = (delta_minutes / 60).floor
    delta_days = (delta_hours / 24).floor
    delta_months = (delta_days / 30).floor
    delta_years = (delta_days / 365).floor

    if delta_years >= 1
      "#{pluralize(delta_years, 'year')} ago"
    elsif delta_months >= 1
      "#{pluralize(delta_months, 'month')} ago"
    elsif delta_days >= 1
      "#{pluralize(delta_days, 'day')} ago"
    elsif delta_hours >= 1
      "#{pluralize(delta_hours, 'hour')} ago"
    elsif delta_minutes >= 1
      "#{pluralize(delta_minutes, 'minute')} ago"
    elsif delta_seconds >= 1
      "#{pluralize(delta_seconds, 'second')} ago"
    else
      "Right now"
    end
  end

  def validation_summary(errors)
    if errors.is_a?(Enumerable) && errors.any?
      render({ :partial => 'shared/validation_summary', :locals => { :errors => errors } })
    end
  end

end
