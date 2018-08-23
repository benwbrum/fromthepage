module AbstractXmlHelper
  require 'rexml/document'

  def source_to_html(source)
    html = source.gsub(/\n/, "<br/>")
    return html
  end

  def xml_to_html(xml_text, preserve_lb=true, flatten_links=false)
    return "" if xml_text.blank?
    xml_text.gsub!(/\n/, "")
    xml_text.gsub!('ISO-8859-15', 'UTF-8')
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
    # get rid of line breaks within other html mark-up
    doc.elements.delete_all("//table//lb")
    # convert line breaks to br or nothing, depending
    doc.elements.each("//lb") do |e|
      lb = REXML::Element.new('span')
      lb.add_text("")
      lb.add_attribute('class', 'line-break')

      if preserve_lb
        if e.attributes['break'] == "no"
          lb.add_text('-')
        end
        lb.add_element(REXML::Element.new('br'))
      else
        unless e.attributes['break']=="no"
          lb.add_text(' ')
        end
      end
      e.replace_with(lb)
    end

    doc.elements.each("//entryHeading") do |e|
      # convert to a span
      depth = e.attributes["depth"]
      title = e.attributes["title"]
      
      span = e
      e.name = 'span'
      span.add_attribute('class', "depth#{depth}")
    end

    if @page
      doc.elements.each("//texFigure") do |e|
        position = e.attributes["position"]
        
        span = REXML::Element.new('img')
        span.add_attribute('src', (file_to_url(TexFigure.artifact_file_path(@page.id, position)) + "?timestamp=" + Time.now.to_i.to_s))
        
        e.replace_with(span)
      end
      
    end

    unless user_signed_in?
      doc.elements.each("//sensitive") do |e|
        e.replace_with(REXML::Comment.new("sensitive information suppressed"))
      end
    end
    # now our doc is correct - what do we do with it?
    my_display_html = ""
    doc.write(my_display_html)
    my_display_html.gsub!("<br/></p>", "</p>")
    my_display_html.gsub!("</p>", "</p>\n\n")
    my_display_html.gsub!("<br/>","<br/>\n")

    return my_display_html.gsub!("<?xml version='1.0' encoding='UTF-8'?>","").gsub('<p/>','').gsub(/<\/?page>/,'').strip!
  end

end
