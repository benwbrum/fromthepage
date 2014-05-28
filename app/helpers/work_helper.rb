module WorkHelper



  def xml_to_docbook(page)
 #   docbook = REXML::Document.new
    internal = REXML::Document.new(page.xml_text)
#    doc.elements.each("//link") do |e|
#      display_text = e.text
#      e.replace_with(REXML::Text.new(display_text))
#    end
    # convert page to section
    internal.elements.each("//page") do |e|
      # create a new section
      docbook_sec = REXML::Element.new('section')
      docbook_sec.add_attribute('id', "page_#{page.id}")
      docbook_sec.add_attribute('label', "")

      # put a title in the section
      sec_title = REXML::Element.new('title')
      sec_title.text = page.title
      docbook_sec.add(sec_title)

      # move former contents of PAGE to SECTION
      e.children.each { |c| docbook_sec.add(c)}
      e.replace_with(docbook_sec)
    end

    # convert p to para
    internal.elements.each("//p") do |e|
      docbook_para = REXML::Element.new('para')
      docbook_para.add(REXML::Text.new("")) # docbook can't handle <para/>
      e.children.each { |c| docbook_para.add(c)}
      e.replace_with(docbook_para)
    end

    # remove lb
    internal.elements.each("//lb") do |e|
      e.replace_with(REXML::Text.new(" "))
    end

    # remove link (for now)
    # TODO convert to footnote
    logger.debug("DEBUG looking for link")
    internal.elements.each("//link") do |e|
      # should we even bother footnoting?
      # compare display text against article title
      display_text = e.text
      article_title = e.attributes['target_title']
      article_id = e.attributes['target_id']
      @displayed_already ||= {}

      if @displayed_already[article_id] || ((display_text.length - article_title.length).abs < 4)
        e.replace_with(REXML::Text.new("#{display_text}"))
      else
        # add the display text
        e.parent.insert_before(e, REXML::Text.new("#{display_text}"))

        # create a footnote node
        fnpara = REXML::Element.new('para')
        fnpara.add(REXML::Text.new(article_title))
        footnote = REXML::Element.new('footnote')
        footnote.add(fnpara)
        e.replace_with(footnote)
        @displayed_already[article_id]=true
      end
    end


    # now our doc is correct - what do we do with it?
    my_display_html = ""
    internal.write(my_display_html)
    logger.debug("DEBUG before slice!=#{my_display_html}")
    my_display_html.slice!("<?xml version='1.0' encoding='ISO-8859-15'?>")
    logger.debug("DEBUG after slice!=#{my_display_html}")
    return my_display_html
  end



  def docbook_index_from_work(work)
    doc = REXML::Document.new();
    index = REXML::Element.new('index')
    doc.add(index)
    sorted_articles = @collection.articles.sort_by do |article|
      article.title.upcase
    end
    for article in sorted_articles
      if article.pages && article.pages.length > 0
        ie = REXML::Element.new('indexentry')
        pie = REXML::Element.new('primaryie')
        em = REXML::Element.new('emphasis')
        title = REXML::Text.new("#{article.title}:")
        em.add(title)
        pie.add(em)
        page_range = nil
        article.pages.each do |p|
          # TODO make this handle hyphenated ranges
          if page_range
            page_range += ", #{p.title_for_print_index}"
          else
            page_range = p.title_for_print_index
          end
        end
        pie.add(REXML::Text.new(page_range))
        # pie.add(REXML::Text.new(entry))
        ie.add(pie)
        index.add(ie)
      end
    end

    string_xml = ""
    doc.write(string_xml)
    return string_xml
  end

end
