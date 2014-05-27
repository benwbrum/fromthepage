module XmlSourceProcessor

  @text_dirty = false
  def source_text=(text)
    @text_dirty = true
    super
  end

  def validate
#    valid = super
#    debug("validate valid=#{valid}")
    if @text_dirty && !validate_source
#      valid = false
    end
#    debug("validate valid=#{valid}")
    debug("validate errors=#{errors.count}")
  end

  def validate_source
    debug('validate_source')
    if self.source_text.blank?
      return
    end
    # split on all begin-braces
    tags = self.source_text.split('[[')
    # remove the initial string which occurs before the first tag
    debug("validate_source: tags to process are #{tags.inspect}")
    tags = tags - [tags[0]]
    debug("validate_source: massaged tags to process are #{tags.inspect}")
    for tag in tags
      debug(tag)
      unless tag.include?(']]')
        errors.add_to_base("Mismatched braces: no closing braces after \"[[#{tag}\"!")
      end
      # just pull the pieces between the braces
      inner_tag = tag.split(']]')[0]
      if inner_tag =~ /^\s*$/
        errors.add_to_base("Error: Blank tag in \"[[#{tag}\"!")
      end
      # check for blank title or display name with pipes
      if inner_tag.include?("|")
        tag_parts = inner_tag.split('|')
        debug("validate_source: inner tag parts are #{tag_parts.inspect}")
        if tag_parts[0] =~ /^\s*$/
          errors.add_to_base("Error: Blank target in \"[[#{inner_tag}]]\"!")
        end
        if tag_parts[1] =~ /^\s*$/
          errors.add_to_base("Error: Blank display in \"[[#{inner_tag}]]\"!")
        end
      end
    end
#    return errors.size > 0
  end

  ##############################################
  # All code to convert transcriptions from source
  # format to canonical xml format belongs here.
  #
  #
  ##############################################
  def process_source
    if !@text_dirty
      return
    end
    self.xml_text = ""

    # convert the source to xml
    xml_string = self.source_text || ""
    xml_string = process_square_braces(xml_string)
    xml_string = process_line_breaks(xml_string)
    xml_string = valid_xml_from_source(xml_string)
    self.xml_text = update_links_and_xml(xml_string)
  end

  def generate_preview
    xml_string = self.source_text
    xml_string = process_square_braces(xml_string)
    xml_string = process_line_breaks(xml_string)
    xml_string = valid_xml_from_source(xml_string)
    xml_string = update_links_and_xml(xml_string, true)
    return xml_string
  end

  def process_square_braces(text)
    processed = ""
    # find every string beginning with [[
    # Ruby 1.8 uses "each", 1.9 uses "each_line"
    if text.respond_to? :each
      each_method_name = :each
    else
      each_method_name = :each_line
    end

    text.send(each_method_name, '[[') do |raw|
      # remove the open brace
      raw.gsub!('[[', '')

      # look for the closing brace ]]
      if raw.include?(']]')
        a = raw.split(']]')
        tag = a[0]
        if tag.include?('|')
          parts = tag.split('|')
          title = parts[0]
          display = parts[1]
        else
          title = tag.gsub(/\n/,' ')
          display = tag
        end
        title = canonicalize_title(title)
        processed << "<link target_title=\"#{title}\">#{display}</link>"
        if a[1]
          processed << a[1]
        end
      else
        processed << raw
      end
    end
    return processed
  end

  def canonicalize_title(title)
    # linebreaks -> spaces
    title = title.gsub(/\n/, ' ')
    # multiple spaces -> single spaces
    title = title.gsub(/\s+/, ' ')
    title
  end

  # transformations converting source mode transcription to xml
  def process_line_breaks(text)
    text="<p>#{text}</p>"
    text = text.gsub(/\n\s*\n/, "</p><p>")
    text = text.gsub(/\n/, "<lb/>")
    return text
  end

  def valid_xml_from_source(source)
    source = source || ""
    safe = source.gsub /\&/, '&amp;'
    safe.gsub! /\&amp;amp;/, '&amp;'

    string = <<EOF
    <?xml version="1.0" encoding="ISO-8859-15"?>
      <page>
        #{safe}
      </page>
EOF
  end

  def update_links_and_xml(xml_string, preview_mode=false)
    # first clear out the existing links
    clear_links
    processed = ""
    # process it
    doc = REXML::Document.new xml_string
    doc.elements.each("//link") do |element|
      # default the title to the text if it's not specified
      if !(title=element.attributes['target_title'])
        title = element.text
      end

      #display_text = element.text
      display_text = ""
      element.children.each do |e|
        display_text += e.to_s
      end
      debug("link display_text = #{display_text}")
      # create new blank articles if they don't exist already
      if !article = Article.find_by_title(title)
        article = Article.new
        article.title = title
        article.collection = collection
        article.save! unless preview_mode
      end
      link_id = create_link(article, display_text) unless preview_mode
      # now update the attribute
      link_element = REXML::Element.new("link")
      element.children.each { |c| link_element.add(c) }
      link_element.add_attribute('target_title', title)
      debug("element="+link_element.inspect)
      debug("article="+article.inspect)
      link_element.add_attribute('target_id', article.id.to_s) unless preview_mode
      link_element.add_attribute('link_id', link_id.to_s) unless preview_mode
      element.replace_with(link_element)
    end
    doc.write(processed)
    return processed
  end

  ##############################################
  # Code to rename links within the text.
  # This assumes that the name change has already
  # taken place within the article table in the DB
  ##############################################
  def rename_article_links(old_title, new_title)
    # handle links of the format [[Old Title|Display Text]]
    self.source_text=self.source_text.gsub(/\[\[#{old_title}\|/, "[[#{new_title}|")
    # handle links of the format [[Old Title]]
    self.source_text=self.source_text.gsub(/\[\[#{old_title}\]\]/, "[[#{new_title}|#{old_title}]]")
    self.save!
  end

  def debug(msg)
    logger.debug("DEBUG: #{msg}")
  end

end
