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

  


  def deeds_for(options={}) 
    limit = options[:limit] || 20

    conditions = nil;
    if options[:types]
      types = options[:types]
      types = types.map { |t| "'#{t}'"}
      conditions = "deed_type IN (#{types.join(',')})"      
    end
    

    if options[:collection]
      # deeds = @collection.deeds.find(:all,  :limit => limit, :order => 'created_at DESC', :conditions => conditions)
      deeds = @collection.deeds.where(conditions).order('created_at DESC').limit(limit)
    else
      restrict = " collections.restricted = 0 "
      conditions = conditions ? conditions + " AND " + restrict : restrict
      # deeds = Deed.find(:all, :limit => limit, :order => 'created_at DESC', :conditions => conditions, :include => :collection)
      logger.debug "in application helper"
      logger.debug "limit: #{limit}"
      # logger.debug "collection is a: #{collection.class}"
      # This is the original
      # deeds = Deed.find(:limit => limit, :order => 'created_at DESC', :conditions => conditions, :include => :collection)
      # this did not work either
      # deeds = Deed.find(:limit => limit, :order => 'created_at DESC', :conditions => conditions)
      # this works for now
      # deeds = [Deed.first, Deed.last] # I just need an array
      deeds = Deed.includes(:collection).where(conditions).order('created_at DESC').limit(limit)
    end
    render({ :partial => 'deed/deeds', 
             :locals => 
              { :limit => limit,
                :deeds => deeds,
                :options => options 
              }
          })
  end

  def time_ago(time)
    delta_seconds = (Time.new - time).floor
    delta_minutes = (delta_seconds / 60).floor
    delta_hours = (delta_minutes / 60).floor
    delta_days = (delta_hours / 24).floor
    
    if delta_days > 1
      "#{delta_days} days ago"
    elsif delta_days == 1
      "1 day ago"
    elsif delta_hours > 1
      "#{delta_hours} hours ago"
    elsif delta_hours == 1
      "1 hour ago"
    elsif delta_minutes > 1
      "#{delta_minutes} minutes ago"
    elsif delta_minutes == 1
      "1 minute ago"
    elsif delta_seconds > 1
      "#{delta_seconds} seconds ago"
    else
      "1 second ago"
    end
  end


end
