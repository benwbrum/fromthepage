module ExportHelper

  def work_to_xhtml(work)
    @work = Work.includes(pages: [{notes: :user}, {page_versions: :user}]).find_by(id: work.id)
    render_to_string :layout => false, :template => "export/show.html.erb"
  end

  def work_to_tei(work)
    params[:format] = 'xml'# if params[:format].blank?

    @work = work
    @context = ExportContext.new

    @user_contributions =
      User.find_by_sql("SELECT  user_id user_id,
                                users.login login,
                                users.real_name real_name,
                                users.display_name display_name,
                                users.guest guest,
                                count(*) edit_count,
                                min(page_versions.created_on) first_edit,
                                max(page_versions.created_on) last_edit
                        FROM    page_versions
                        INNER JOIN pages
                            ON page_versions.page_id = pages.id
                        INNER JOIN users
                            ON page_versions.user_id = users.id
                        WHERE pages.work_id = #{@work.id}
                          AND page_versions.transcription IS NOT NULL
                        GROUP BY user_id
                        ORDER BY count(*) DESC")

    @work_versions = PageVersion.joins(:page).where(['pages.work_id = ?', @work.id]).order("work_version DESC").includes(:page).all

    @all_articles = @work.articles

    @person_articles = @all_articles.joins(:categories).where(categories: {title: 'People'})
    @place_articles = @all_articles.joins(:categories).where(categories: {title: 'Places'})
    @other_articles = @all_articles.joins(:categories).where.not(categories: {title: 'People'})
                      .where.not(categories: {title: 'Places'})

    ### Catch the rendered Work for post-processing
    xml = render_to_string :layout => false, :template => "export/tei.html.erb"
    post_process_xml(xml, @work)
  end



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
    tei = "          <category xml:id=\"S#{subject.id}\">\n"
    tei << "            <catDesc>\n"
    tei << "              <term>#{ERB::Util.html_escape(subject.title)}</term>\n"
    tei << '              <note type="categorization">Categories:'
    subject.categories.each do |category|
      tei << '<ab>'
      category.ancestors.reverse.each do |parent|
        if parent.root? 
          category_class = "#category #root"
        else
          category_class = "#category #branch"
        end
        tei << "<ptr ana=\"#{category_class}\" target=\"#C#{parent.id}\">#{parent.title}</ptr> -- "
      end
      tei << "<ptr ana=\"#category #leaf#{' #root' if category.root?}\" target=\"#C#{category.id}\">#{category.title}</ptr>"
      tei << "</ab>\n"
    end
    tei << "              </note>\n"
    unless subject.latitude.blank?
      tei << "              <note type=\"geography\">\n"
      tei << "                <geo>#{subject.latitude}, #{subject.longitude}</geo>\n"
      tei << "              </note>\n"
    end

    tei << "              <gloss>#{xml_to_export_tei(subject.xml_text,ExportContext.new, "SD#{subject.id}")}</gloss>\n" unless subject.source_text.blank?
    tei << "            </catDesc>\n"
    tei << "          </category>\n"

    tei
  end


  def seen_subject_to_tei(subject, parent_category)
    tei = "<category xml:id=\"C#{parent_category.id}S#{subject.id}\">\n"
    tei << "<catDesc>\n"
    tei << "<term><rs ref=\"S#{subject.id}\">#{ERB::Util.html_escape(subject.title)}</rs></term>\n"
    tei << "</catDesc>\n"
    tei << "</category>\n"

    tei
    
  end

  def xml_to_export_tei(xml_text, context, page_id = "", add_corrsp=false)

    return "" if xml_text.blank?
#    xml_text.gsub!(/\n/, "")
    xml_text.gsub!('ISO-8859-15', 'UTF-8')
    xml_text.gsub!('&', '&amp;')
    xml_text.gsub!('&amp;amp;', '&amp;')

    # xml_text = titles_to_divs(xml_text, context)
    doc = REXML::Document.new(xml_text)
    #paras_string = ""

    my_display_html = ""
    doc.elements.each_with_index("//p") do |e,i|
      transform_links(e)
      transform_expansions(e)
      transform_regularizations(e)
      e.add_attribute("xml:id", "#{page_id_to_xml_id(page_id, context.translation_mode)}P#{i}")
      if add_corrsp
        e.add_attribute("corresp", "#{page_id_to_xml_id(page_id, !context.translation_mode)}P#{i}")
      end
      my_display_html << e.to_s
    end

    return my_display_html.gsub('<lb/>', "<lb/>\n").gsub('</p>', "\n</p>\n\n").gsub('<p>', "<p>\n").encode('utf-8')
  end

  def transform_expansions(p_element)
    p_element.elements.each('//expan') do |expan|
      orig = expan.attributes['orig']
      unless orig.blank?
        choice = REXML::Element.new("choice")
        tei_expan = REXML::Element.new("expan")
        expan.children.each { |c| tei_expan.add(c) }
        choice.add(tei_expan)
        unless orig.blank?
          tei_abbr = REXML::Element.new("abbr")
          tei_abbr.add_text(orig)
          choice.add(tei_abbr)
        end
        expan.replace_with(choice)
      end
    end
  end

  def transform_regularizations(p_element)
    p_element.elements.each('//reg') do |reg|
      orig = reg.attributes['orig']
#      binding.pry
      unless orig.blank? || reg.parent.name == 'choice'
        choice = REXML::Element.new("choice")
        tei_reg = REXML::Element.new("reg")
        reg.children.each { |c| tei_reg.add(c) }
        choice.add(tei_reg)
        unless orig.blank?
          tei_orig = REXML::Element.new("orig")
          tei_orig.add_text(orig)
          choice.add(tei_orig)
        end
        reg.replace_with(choice)
      end
    end
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
