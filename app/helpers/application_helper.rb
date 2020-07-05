module ApplicationHelper
  
  #dead code
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
      deeds = @collection.deeds.active.where(condition).order('deeds.created_at DESC').limit(limit)
    else
      #restricting to visible collections first speeds up the query
      limited = Deed.where(is_public: true)
      if options[:owner]
        owner = User.friendly.find(options[:owner])
        deeds = limited.where(collection_id: owner.all_owner_collections.ids).order('deeds.created_at DESC').limit(limit)
      else
        deeds = limited.where(condition).order('deeds.created_at DESC').limit(limit)
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
  
  def language_attrs(collection)
    direction = Rtl.rtl?(collection.text_language) ? 'rtl' : 'ltr'
    
    language = ISO_639.find_by_code(collection.text_language)
    language = ISO_639.find_by_code('en') if language.nil?

    display_language = language.alpha2

    attrs = {
      'lang'=>"#{display_language}", 
      'dir'=>"#{direction}", 
      'class'=>"#{direction}"
    }
    return attrs
  end

  def fromthepage_version
    Fromthepage::Application::Version
  end

  def value_to_html(value)
    if value.is_a? String
      return value
    elsif value.is_a? Array
      return value.map {|e| e["@value"]}.join("; ")
    end
  end

  def html_metadata_from_work(work)
    html_metadata(JSON.parse(work.original_metadata))
  end

  def html_metadata(metadata_hash)
    html = ""
    metadata_hash.each do |md|
      html += "<p><b>#{md["label"]}</b>: #{value_to_html(md["value"])} </p>"
    end
    html
  end


end
