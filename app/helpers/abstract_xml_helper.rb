module AbstractXmlHelper
  require 'rexml/document'

  def source_to_html(source)
    html = source.gsub(/\n/, "<br/>")
    return html
  end

  def xml_to_html(xml_text, preserve_lb=true, flatten_links=false, collection=nil)
    return "" if xml_text.blank?
    xml_text.gsub!(/\n/, "")
    xml_text.gsub!('ISO-8859-15', 'UTF-8')

    if preserve_lb
      xml_text.gsub!("<lb break='no'/> ", "-<br />")
    end

    @collection ||= collection

    doc = REXML::Document.new(xml_text)
    #unless subject linking is disabled, do this
    unless @collection.subjects_disabled
      doc.elements.each("//link") do |e|

        title = e.attributes['target_title']
        id = e.attributes['target_id']
        # first find the articles
        anchor = REXML::Element.new("a")
        #anchor.text = display_text
        if id
          if flatten_links
            anchor.add_attribute("href", "#article-#{id}")
          else
            anchor.add_attribute("data-tooltip", url_for(:controller => 'article', :action => 'tooltip', :article_id => id, :collection_id => @collection.slug))
            anchor.add_attribute("href", url_for(:controller => 'article', :action => 'show', :article_id => id))
          end
        else
          # preview mode for this link
          anchor.add_attribute("href", "#")
        end
        anchor.add_attribute("title", title)
        e.children.each { |c| anchor.add(c) }
        e.replace_with(anchor)
      end
    end

    doc.elements.each("//abbr") do |e|
      expan = e.attributes['expan']
      span = REXML::Element.new("span")
      span.add_attribute("class", "expanded-abbreviation")
      span.add_text(expan)
      inner_span = REXML::Element.new("span")
      inner_span.add_attribute("class", "original-abbreviation")
      e.children.each { |c| inner_span.add(c) }
      span.add(inner_span)
      e.replace_with(span)
    end

    doc.elements.each("//expan") do |e|
      orig = e.attributes['orig']
      span = REXML::Element.new("span")
      span.add_attribute("class", "expanded-abbreviation")
      e.children.each { |c| span.add(c) }
      inner_span = REXML::Element.new("span")
      inner_span.add_attribute("class", "original-abbreviation")
      inner_span.add_text(orig)
      span.add(inner_span)
      e.replace_with(span)
    end

    doc.elements.each("//reg") do |e|
      orig = e.attributes['orig']

      span = REXML::Element.new("span")
      span.add_attribute("class", "expanded-abbreviation")
      e.children.each { |c| span.add(c) }
      inner_span = REXML::Element.new("span")
      inner_span.add_attribute("class", "original-abbreviation")
      inner_span.add_text(orig)
      span.add(inner_span)
      e.replace_with(span)
    end

    # get rid of line breaks within other html mark-up
    doc.elements.delete_all("//table/lb")
    doc.elements.delete_all("//table/row/lb")

    # convert line breaks to br or nothing, depending
    doc.elements.each("//lb") do |e|
      lb = REXML::Element.new('span')
      lb.add_text("")
      lb.add_attribute('class', 'line-break')

      if preserve_lb
        if e.attributes['break'] == "no"
          sib = e.previous_sibling
          if sib.kind_of? REXML::Element
            sib.add_text('-')
          else
            sib.value=sib.value+'-'
          end
        end
        e.replace_with(REXML::Element.new('br'))
      else
        if params[:action] == "read_work" || params[:action] == 'needs_review_pages' || params[:action] == 'paged_search' 
          if e.attributes['break'] == "no"
            lb.add_text('')
          else
            lb.add_text(' ')
            lb.add_attribute('class', 'line-break')
          end
        else
          if e.attributes['break'] == "no"
            lb.add_text('-')
          end
        end
      end

      e.replace_with(lb) unless preserve_lb
    end

    doc.elements.each("//entryHeading") do |e|
      # convert to a span
      depth = e.attributes["depth"]
      title = e.attributes["title"]
      
      span = e
      e.name = 'span'
      span.add_attribute('class', "depth#{depth}")
    end

    doc.elements.each("//hi") do |e|
      rend = e.attributes["rend"]
      span=e
      case rend
      when 'sup'
        span.name='sup'
      when 'underline'
        span.name='u'
      when 'italic'
        span.name='i'
      when 'bold'
        span.name='i'
      when 'sub'
        span.name='sub'
      when 'str'
        span.name='strike'
      end
    end

    doc.elements.each("//add") do |e|
      e.name='span'
      e.add_attribute('class', "addition")
    end

    doc.elements.each("//figure") do |e|
      rend = e.attributes["rend"]
      if rend == 'hr'
        e.name='hr'
      else
        e.name='span'
        e.add_text("{#{rend.titleize}}")
      end
    end

    doc.elements.each("//unclear") do |e|
      unclear = REXML::Element.new('span')
      unclear.add_text("[")
      unclear.add_attribute('class', 'unclear')
      e.children.each { |c| unclear.add(c) }
      unclear.add_text("]")
      e.replace_with(unclear)
    end

    doc.elements.each("//gap") do |e|
      gap = REXML::Element.new('span')
      gap.add_text("[...]")
      gap.add_attribute('class', 'gap')
      e.replace_with(gap)
    end

    doc.elements.each("//stamp") do |e|
      stamp_type = e.attributes["type"] || ''
      stamp = REXML::Element.new('span')
      stamp.add_text("{#{stamp_type.titleize} Stamp}")
      stamp.add_attribute('class', 'stamp')
      e.replace_with(stamp)
    end



    doc.elements.each("//table") do |e|
      rend = e.attributes["rend"]
      if rend == 'ruled'
        e.add_attribute('class', 'tabular')
      end
    end

    doc.elements.each("//row") do |e|
      e.name='tr'
    end


    doc.elements.each("//cell") do |e|
      e.name='td'
    end

    if @page
      doc.elements.each("//texFigure") do |e|
        position = e.attributes["position"]
        
        span = REXML::Element.new('img')
        span.add_attribute('src', (file_to_url(TexFigure.artifact_file_path(@page.id, position)) + "?timestamp=" + Time.now.to_i.to_s))
        
        e.replace_with(span)
      end
      
    end

    # now our doc is correct - what do we do with it?
    my_display_html = ""
    doc.write(my_display_html)
    my_display_html.gsub!("</p>", "</p>\n\n")
    my_display_html.gsub!("<br/>","<br/>\n")

    return my_display_html.gsub!("<?xml version='1.0' encoding='UTF-8'?>","").gsub('<p/>','').gsub(/<\/?page>/,'').strip!
  end

end
