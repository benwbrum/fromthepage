module ApplicationHelper
  
  def billing_host
    if defined? BILLING_HOST
      BILLING_HOST
    else
      if params[:debug_billing]
        session[:debug_billing]=true
      end
      if session[:debug_billing]
        if defined? BILLING_HOST_DEVELOPMENT
          BILLING_HOST_DEVELOPMENT
        else
          nil
        end
      else
        nil
      end
    end
  end

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
  def display_categories(categories, parent_id, expanded=false, &block)
    ret = "<ul>\n"
      for category in categories
        if category.parent_id == parent_id
          ret << "<li#{' class="expanded"' if expanded}>"
          ret << yield(category)
          ret << display_categories(category.children, category.id, expanded, &block) if category.children.any?
          ret << "</li>"
        end
      end
    ret << "</ul>\n"
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
      deeds = @collection.deeds.active.includes(:page, :user).where(condition).order('deeds.created_at DESC').limit(limit)
    else
      #restricting to visible collections first speeds up the query
      limited = Deed.joins(:collection).where('collections.restricted = 0')
      if options[:owner]
        owner = User.friendly.find(options[:owner])
        deeds = limited.active.includes(:page, :user, collection: [:works]).where(collection_id: owner.all_owner_collections.ids).order('deeds.created_at DESC').limit(limit)
      else
        deeds = limited.active.includes(:page, :user, collection: [:works]).where(condition).order('deeds.created_at DESC').limit(limit)
      end
    end
    render({ :partial => 'deed/deeds', :locals => { :limit => limit, :deeds => deeds, :options => options } })
  end

  def validation_summary(errors)
    if errors.is_a?(Enumerable) && errors.any?
      render({ :partial => 'shared/validation_summary', :locals => { :errors => errors } })
    end
  end

  def page_title(title=nil)
    base_title = 'FromThePage'

    if title.blank?
      base_title
    else
      current_page?('/') ? title : "#{title.squish} | #{base_title}"
    end
  end

  def work_title 
    if @document_set
      "#{@work.title} (#{@document_set.title})"
    elsif @collection
      "#{@work.title} (#{@collection.title})"
    else
      @work.title
    end
  end
  
  def pontiiif_server
    Rails.application.config.respond_to?(:pontiiif_server) && Rails.application.config.pontiiif_server
  end

  def language_attrs(collection)
    direction = Rtl.rtl?(collection.text_language) ? 'rtl' : 'ltr'
    language = !collection.text_language.nil? ? collection.text_language : nil
    attrs = {'lang'=>"#{language}", 'dir'=>"#{direction}", 'class'=>"#{direction}"}
    return attrs
  end

end