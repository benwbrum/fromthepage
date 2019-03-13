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
    seen_subjects = []
    categories.each do |category|
      tei << category_to_tei(category, subjects, seen_subjects)
    end
    tei << "</taxonomy>\n"
    tei = REXML::Document.new(tei).to_s
    
    tei
  end

  def category_to_tei(category, subjects, seen_subjects) 
    has_content = false
    tei = ""
    tei << "<category xml:id=\"C#{category.id}\">\n"
    tei << "<catDesc>#{category.title}</catDesc>\n"
    category.articles.where("id in (?)", subjects.map {|s| s.id}).each do |subject|
      binding.pry if subject.title.match /&/
      has_content = true
      if seen_subjects.include?(subject)
        tei << seen_subject_to_tei(subject, category)
      else
        tei << subject_to_tei(subject)
        seen_subjects << subject
      end
    end
    category.children.each do |child|
      has_content = true
      tei << category_to_tei(child, subjects, seen_subjects)
    end
    tei << "</category>\n"

    has_content ? tei : ""
  end
  
  def subject_to_tei(subject)
    tei = "<category xml:id=\"S#{subject.id}\">\n"
    tei << "<catDesc>\n"
    tei << "<term>#{REXML::Text.new(subject.title,true,nil,false).to_s}</term>\n"
    tei << "<gloss>#{xml_to_export_tei(subject.xml_text,ExportContext.new, "SD#{subject.id}")}</gloss>\n" unless subject.source_text.blank?
    tei << "</catDesc>\n"
    tei << "</category>\n"

    tei
  end


  def seen_subject_to_tei(subject, parent_category)
    tei = "<category xml:id=\"C#{parent_category.id}S#{subject.id}\">\n"
    tei << "<catDesc>\n"
    tei << "<term><rs ref=\"S#{subject.id}\">#{REXML::Text.new(subject.title,true,nil,false).to_s}</rs></term>\n"
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
    doc.elements.each_with_index("//table") do |table|
      transform_table(table)
    end
    doc.elements.each_with_index("//p") do |e,i|
      transform_tags(e)
      e.add_attribute("xml:id", "#{page_id_to_xml_id(page_id, context.translation_mode)}P#{i}")
      e.add_attribute("corresp", "#{page_id_to_xml_id(page_id, !context.translation_mode)}P#{i}")
      my_display_html << e.to_s
    end

    return my_display_html.gsub('<lb/>', "<lb/>\n").gsub('</p>', "\n</p>\n\n").gsub('<p>', "<p>\n").encode('utf-8')
  end

  def add_bk_attributes(cell, source)
    index = source.xpath.match(/\[(\d+)\]$/)[1].to_i
    if index == 1
      cell.add_attribute('ana', '#bk_when')
    elsif index == 2
      cell.add_attribute('ana', '#bk_what')
      parse_commodity_cell(cell)
    elsif index >= 3
      cell.add_attribute('ana', '#bk_amount')
      if index == 3
        text_to_measure(cell, cell.text, 'pounds', 'currency')
      elsif index == 4
        text_to_measure(cell, cell.text, 'shillings', 'currency')
      elsif index == 5
        text_to_measure(cell, cell.text, 'pence', 'currency')
      end        
    end
  end  

  def parse_commodity_cell(cell)
    measures = []
    cell.elements.each do |link|
      prefix = link.previous_sibling.to_s
      suffix = link.next_sibling.to_s
      if prefix.match(/(\S+)\s*(\S+)\s*$/)
        quantity = $1
        unit = $2
        if unit.match(/^\d+$/)
          # probably no actual unit
          quantity = unit
          unit = nil
        end
      end      
      if suffix.match(/\s*(\S+)/)
        price = $1       
      end
      commodity = link.attribute('target_title').value
      
      measure=REXML::Element.new("measure")
      measure.add_attribute('quantity', quantity)
      measure.add_attribute('unit',unit) if unit
      measure.add_attribute('commodity', commodity)
      # TODO use original in closing capture group
      measure.add_text(quantity)
      measure.add_text(' ')
      measure.add_text(unit)
      measure.add(link)
      measure.add_text(price)
      
      measures << measure
    end
    cell.children.each do |child|
      child.remove
    end
    measures.each do |measure|
      cell.add(measure)
    end
  end

  def text_to_measure(cell, quantity, unit, commodity, price=nil)
    measure=REXML::Element.new("measure")
    cell.children.each { |c| measure.add(c) }
    measure.add_attribute('quantity', quantity)
    measure.add_attribute('unit',unit)
    measure.add_attribute('commodity', commodity)
#    measure.add_attribute('#bk_price', price) if price
#    cell.children.each
    cell.add(measure)
        
  end

  def transform_table(table)
    clean = REXML::Element.new('table')
    table.elements.each('tbody/tr') do |tr|
      row = REXML::Element.new('row')
      row.add_attribute('ana', "#bk_entry")
      tr.elements.each('td') do |td|
        cell = REXML::Element.new('cell')
        td.children.each { |c| cell.add(c) }
        add_bk_attributes(cell, td)
        row.add(cell)
      end
      clean.add(row)
    end
    table.replace_with(clean)
  end
  # def titles_to_divs(xml_text, context)
    # logger.debug("FOO #{context.div_stack.count}\n")
    # xml_text.scan(/entryHeading title=\".s*\" depth=\"(\d)\"")
  # end

  def transform_tags(p_element)
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
      gap.add_attribute('ana', '#bk_party #bk_from #bk_account')
      entryHeading.children.each { |c| gap.add(c) }
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
    p_element.elements.each('//sup') do |sup|
      add = REXML::Element.new("add")

      add.add_attribute("place", "above")
      sup.children.each { |c| add.add(c) }
      sup.replace_with(add)
    end
  end

  def post_process_xml(xml, work)
    if work.pages_are_meaningful?
      return xml
    else
      doc = REXML::Document.new(xml)
      doc_body = doc.get_elements('//body').first
      
      # Process Sections
      current_depth = 1
      sections = []
      
      doc_body.children.each {|e|
      
        if(e.node_type != :text && e.get_elements('head').length > 0)
          header = e.get_elements('head').first
          
          # Create the new section
          section = REXML::Element.new('section')
          section.add_attribute('depth', header.attributes['depth']) 

          # Handle where to put the new section
          if sections.empty?
            # Inserts the new section into the doc before the current element
            e.parent.insert_before(e, section)
            sections.push(section)
            # section.add(e)
          # elsif current_depth < header.attributes['depth'].to_i
          #   sections.first.add(section)
          #   # section.add(e)
          # elsif current_depth == header.attributes['depth'].to_i
          #   sections.pop()
          #   sections.first.add(section)
          #   # section.add(e)
          else
            ## This still isn't working right

          end

          # Update the accumulator
          sections.push(section)
          current_depth = section.attributes['depth'].to_i
        end

        # Adds the current element to the new section at the right location
        sections.first.add(e) unless sections.empty?
      
      }
      
      return doc
    end
  end
end
