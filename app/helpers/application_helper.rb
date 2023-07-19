module ApplicationHelper
  
  def contact_form_token
    ("#{Time.now.year}#{Time.now.month}#{Time.now.day}".to_i * 32 / 7)
  end


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

  def profile_picture(user, gravatar_size = nil)
    render({ 
              :partial => 'shared/profile_picture',
              :locals => { :user => user, :gravatar_size => gravatar_size }
      })
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


    suppress_collection = false
    if options[:collection]
      deeds = @collection.deeds.active.where(condition).order('deeds.created_at DESC').limit(limit)
      suppress_collection = true
    else
      #restricting to visible collections first speeds up the query
      limited = Deed.where(is_public: true)
      if options[:owner]
        owner = User.friendly.find(options[:owner].id)
        deeds = limited.where(collection_id: owner.all_owner_collections.ids).order('deeds.created_at DESC').limit(limit)
      elsif options[:user_id]
        deeds = Deed.where(condition).order('deeds.created_at DESC').limit(limit)
      else
        deeds = limited.where(condition).order('deeds.created_at DESC').limit(limit)
      end
    end
    options[:suppress_collection] = suppress_collection
    render({ :partial => 'deed/deeds', :locals => { :limit => limit, :deeds => deeds, :options => options} })
  end

  def show_prerender(prerender, locale) 
    begin
      prerenders = JSON.parse(prerender)
      unless rendered = prerenders[locale.to_s] # show prerender in specified locale
        # prerender doesn't have specified locale, show first fallback that prerender has
        fallback = (I18n.fallbacks[locale].map(&:to_s) & prerenders.keys).first
        rendered = prerenders[fallback]
      end
      rendered
    rescue JSON::ParserError => e
      # prerender is a string, not hash
      prerender
    end
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
      return value # scalar value
    elsif value.is_a? Array
      if value.first.is_a? String
        return value.join("; ") # simple array
      else
        # array of language pairs
        return value.map {|e| e["@value"]}.join("; ")
      end
    elsif value.is_a? Hash
      # is this a pre-IIIF-v3 multi-language value?
      if value.keys.include?('@language') && value.keys.include?('@value')
        return value["@value"]
      else
        return value.values.map{|value_array| value_array.first}.join('<br/>')
      end
    end
  end

  def html_metadata_from_work(work)
    if work.original_metadata.blank?
      ""
    else
      html_metadata(JSON.parse(work.original_metadata))
    end
  end

  def html_metadata(metadata_hash)
    html = ""
    metadata_hash.each do |md|
      label = md['label']
      if label.is_a? Array
        label = label.first['@value']
      elsif label.is_a? Hash
        label = label.values.map{|label_array| label_array.first}.join(" / ")
      end
      value = md['value']

      html += "<p><b>#{label}</b>: #{value_to_html(value)} </p>\n\n"
    end
    html
  end

  def target_collection_options(default)
    option_data = {}
    current_user.collections.sort { |a,b| a.title <=> b.title }.each do |c| 
      option_data[c.title]=c.id 
      c.document_sets.sort { |a,b| a.title <=> b.title }.each do |set|
        option_data[" -- #{set.title}"] = "D#{set.id}"
      end
    end

    if @collection
      if @collection.is_a? Collection
        options_for_select(option_data, @collection.id)
      else
        options_for_select(option_data, "D#{@collection.id}")
      end
    else
      options_for_select(option_data)
    end      
  end

  def feature_enabled?(feature)
    session[:features] && session[:features][feature.to_s]
  end

  # makes an intro block into a snippet by removing style tag, stripping tags, and truncating
  def to_snippet(intro_block)
    # remove style tag, Loofah.fragment.text doesn't do this (strip_tags does)
    doc = Nokogiri::HTML(intro_block)
    doc.xpath('//style').each { |n| n.remove } 
    # strip tags and truncate
    truncate(Loofah.fragment(doc.to_s).text(encode_special_chars: false), length: 300, separator: ' ') || '' 
  end

  def timeago(time, options = {})
    options[:class] ||= "timeago"
    content_tag(:time, time.to_s, options.merge(datetime: time.getutc.iso8601)) if time
  end

  def mobile_device?
    !!(request.user_agent =~ /Mobile/)
  end
end
