module TeiHelper
  include DisplayHelper

  def xml_to_tei(xml_text, preserve_lb=true)
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

    # convert HTML tables to TEI tables
    doc.elements.each("//table") do |e|
      table = REXML::Element.new("table")
      # does the table have a header?
      if e.elements["thead"]
        # convert the header into a row element with role="label"
        header = REXML::Element.new("row")
        header.add_attribute("role", "label")
        e.elements.each("thead/tr/th") do |th|
          # convert the th into a cell element
          cell = REXML::Element.new("cell")
          cell.add_attribute("role", "data")
          cell.add_child(th.children)
        end
        table.add(header)
      end
      # now convert the body of the table
      e.elements.each("tbody/tr") do |tr|
        row = REXML::Element.new("row")
        tr.elements.each("td") do |td|
          cell = REXML::Element.new("cell")
          cell.add_attribute("role", "data")
          cell.add_child(td.children)
          row.add(cell)
        end
        table.add(row)
      end # end of tbody
      e.replace_with(table)
    end # end of table
    # now delete any lb elements from tables elements in the document
    doc.elements.each("//table") do |table|
      table.elements.each("//lb") do |lb|
        lb.remove
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
    my_display_html.gsub!("<?xml version='1.0' encoding='ISO-8859-15'?>","")
    return my_display_html
  end
end
