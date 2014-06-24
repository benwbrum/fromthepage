module AbstractXmlHelper
  require 'rexml/document'

  def source_to_html(source)
    html = source.gsub(/\n/, "<br />")
    return html
  end

  def xml_to_html(xml_text, preserve_lb=true, flatten_links=false)
    return "" if xml_text.blank?
    xml_text.gsub!(/\n/, "")
    doc = REXML::Document.new(xml_text)
    doc.elements.each("//link") do |e|
      title = e.attributes['target_title']
      id = e.attributes['target_id']
      # first find the articles
      anchor = REXML::Element.new("a")
#      anchor.text = display_text
      if id
        if flatten_links
          anchor.add_attribute("href", "#article-#{id}")
        else
          anchor.add_attribute("href",
                               url_for(:controller => 'article',
                                       :action => 'show',
                                       :article_id => id,
                                       :title=> title))

        end
      else
        # preview mode for this link
        anchor.add_attribute("href", "#")
      end
      anchor.add_attribute("title",
                           title)
      e.children.each { |c| anchor.add(c) }
      e.replace_with(anchor)
    end
    # get rid of line breaks within other html mark-up
    doc.elements.delete_all("//table//lb")
    # convert line breaks to br or nothing, depending
    doc.elements.each("//lb") do |e|
      if preserve_lb
        e.replace_with(REXML::Element.new('br'))
      else
        lb = REXML::Element.new('span')
        lb.add_text(' ')
        lb.add_attribute('class', 'line-break')
        e.replace_with(lb)
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
    return my_display_html.gsub!("<?xml version='1.0' encoding='ISO-8859-15'?>","").gsub('<p/>','')
  end


end
