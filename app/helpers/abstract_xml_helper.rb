module AbstractXmlHelper
  require 'rexml/document'

  def source_to_html(source)
    html = source.gsub(/\n/, "<br />")
    return html
  end

  def xml_to_html(xml_text, preserve_lb=true)
    xml_text.gsub!(/\n/, "")
    doc = REXML::Document.new(xml_text)
    doc.elements.each("//link") do |e| 
      title = e.attributes['target_title']
      id = e.attributes['target_id']
      # first find the articles
      anchor = REXML::Element.new("a")
#      anchor.text = display_text
      if id
        anchor.add_attribute("href",
                             url_for(:controller => 'article',
                                     :action => 'show',
                                     :article_id => id,
                                     :title=> title))
      else
        # preview mode for this link
        anchor.add_attribute("href", "#")
      end
      anchor.add_attribute("title",
                           title)
      e.children.each { |c| anchor.add(c) }
      e.replace_with(anchor)
    end
    if preserve_lb
      doc.elements.each("//lb") do |e| 
        e.replace_with(REXML::Element.new('br'))
      end
    end
    # now our doc is correct - what do we do with it?
    my_display_html = ""
    doc.write(my_display_html)
    return my_display_html
  end


end
