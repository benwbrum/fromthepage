module ExportHelper

  def xml_to_export_tei(xml_text, type=nil)

    return "" if xml_text.blank?
#    xml_text.gsub!(/\n/, "")
    doc = REXML::Document.new(xml_text)
    #paras_string = ""
    
    my_display_html = ""
    doc.elements.each("//p") do |e|
      transform_links(e, type)
      my_display_html << e.to_s
    end
    return my_display_html
  end

  def transform_links(p_element, type)
    p_element.elements.each('//link') do |link|
      rs = REXML::Element.new("rs")

      id = link.attributes['target_id']
      rs.add_attribute("ref", "#S#{id}")
      rs.add_attribute("type", type) if type

      link.children.each { |c| rs.add(c) }
      link.replace_with(rs)
     
    end
    p_element.elements.each('//sensitive') do |sensitive|
      gap = REXML::Element.new("gap")

      gap.add_attribute("reason", "redacted")
      sensitive.replace_with(gap)
    end
    p_element.elements.each('//a') do |a|
      rs = REXML::Element.new("rs")
      href = a.attributes['href']

      rs.add_attribute("ref", href)
      a.children.each { |c| rs.add(c) }
      a.replace_with(rs)
    end
    p_element.elements.each('//strike') do |strike|
      del = REXML::Element.new("del")

      del.add_attribute("rend", "overstrike")
      strike.children.each { |c| del.add(c) }
      strike.replace_with(del)
    end
    p_element.elements.each('//u') do |u|
      hi = REXML::Element.new("hi")

      hi.add_attribute("rend", "underline")
      u.children.each { |c| hi.add(c) }

      u.replace_with(hi)
    end
  end



end
