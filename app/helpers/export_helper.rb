module ExportHelper

  def page_id_to_xml_id(id, translation=false)
    return "" if id.blank?
    
    if translation
      "TTP#{id}"
    else
      "OTP#{id}"
    end
  end

  def tei_taxonomy(categories, subjects)
    tei = "<taxonomy>\n"
    categories.each do |category|
      tei << category_to_tei(category, subjects)
    end
    tei << "</taxonomy>\n"
    
    tei
  end

  def category_to_tei(category, subjects) 
    tei = "<category xml:id=\"C#{category.id}\">\n"
    tei << "<catDesc>#{category.title}</catDesc>\n"
    category.articles.where("id in (?)", subjects.map {|s| s.id}).each do |subject|
      tei << subject_to_tei(subject)
    end
    category.children.each do |child|
      tei << category_to_tei(child, subjects)
    end
    tei << "</category>\n"

    tei
  end
  
  def subject_to_tei(subject)
    tei = "<category xml:id=\"S#{subject.id}\">\n"
    tei << "<catDesc>\n"
    tei << "<term>#{subject.title}</term>\n"
    tei << "<gloss>#{xml_to_export_tei(subject.xml_text,ExportContext.new, "SD#{subject.id}")}</gloss>\n" unless subject.source_text.blank?
    tei << "</catDesc>\n"
    tei << "</category>\n"

    tei
  end


  def xml_to_export_tei(xml_text, context, page_id = "")

    return "" if xml_text.blank?
#    xml_text.gsub!(/\n/, "")
    xml_text.gsub!('ISO-8859-15', 'UTF-8')
    # xml_text = titles_to_divs(xml_text, context)
    doc = REXML::Document.new(xml_text)
    #paras_string = ""

    my_display_html = ""
    doc.elements.each_with_index("//p") do |e,i|
      transform_links(e)
      e.add_attribute("xml:id", "#{page_id_to_xml_id(page_id, context.translation_mode)}P#{i}")
      e.add_attribute("corresp", "#{page_id_to_xml_id(page_id, !context.translation_mode)}P#{i}")
      my_display_html << e.to_s
    end

    return my_display_html.gsub('<lb/>', "<lb/>\n").gsub('</p>', "\n</p>\n\n").gsub('<p>', "<p>\n").encode('utf-8')
  end

  # def titles_to_divs(xml_text, context)
    # logger.debug("FOO #{context.div_stack.count}\n")
    # xml_text.scan(/entryHeading title=\".s*\" depth=\"(\d)\"")
  # end

  def transform_links(p_element)
    p_element.elements.each('//link') do |link|
      rs = REXML::Element.new("rs")

      id = link.attributes['target_id']
      rs.add_attribute("ref", "#S#{id}")

      link.children.each { |c| rs.add(c) }
      link.replace_with(rs)

    end
    p_element.elements.each('//sensitive') do |sensitive|
      gap = REXML::Element.new("gap")

      gap.add_attribute("reason", "redacted")
      sensitive.replace_with(gap)
    end
    p_element.elements.each('//entryHeading') do |entryHeading|
      gap = REXML::Element.new("head")

      gap.add_attribute("depth", entryHeading.attributes["depth"])
      gap.add_text(entryHeading.attributes["title"])
      entryHeading.replace_with(gap)
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
    p_element.elements.each('//s') do |strike|
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
    p_element.elements.each('//i') do |i|
      hi = REXML::Element.new("hi")

      hi.add_attribute("rend", "italic")
      i.children.each { |c| hi.add(c) }

      i.replace_with(hi)
    end
  end



end
