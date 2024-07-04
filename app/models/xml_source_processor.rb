module XmlSourceProcessor

  @text_dirty = false
  @translation_dirty = false
  # @fields = false

  def source_text=(text)
    @text_dirty = true
    super
  end

  def source_translation=(translation)
    @translation_dirty = true
    super
  end

  def validate_source
    return if source_text.blank?

    validate_links(source_text)
  end

  def validate_source_translation
    return if source_translation.blank?

    validate_links(source_translation)
  end

  # check the text for problems or typos with the subject links
  def validate_links(text)
    error_scope = [:activerecord, :errors, :models, :xml_source_processor]
    # split on all begin-braces
    tags = text.split('[[')
    # remove the initial string which occurs before the first tag
    debug("validate_source: tags to process are #{tags.inspect}")
    tags -= [tags[0]]
    debug("validate_source: massaged tags to process are #{tags.inspect}")
    tags.each do |tag|
      debug(tag)

      if tag.include?(']]]')
        errors.add(:base,
          I18n.t('subject_linking_error', scope: error_scope) + I18n.t('tags_should_not_use_3_brackets', scope: error_scope))
        return
      end
      unless tag.include?(']]')
        tag = tag.strip
        errors.add(:base,
          I18n.t('subject_linking_error',
            scope: error_scope) + I18n.t('wrong_number_of_closing_braces', tag: "\"[[#{tag}\"", scope: error_scope))
      end

      # just pull the pieces between the braces
      inner_tag = tag.split(']]')[0]
      if inner_tag =~ /^\s*$/
        errors.add(:base,
          I18n.t('subject_linking_error', scope: error_scope) + I18n.t('blank_tag_in', tag: "\"[[#{tag}\"", scope: error_scope))
      end

      # check for unclosed single bracket
      if inner_tag.include?('[') && inner_tag.exclude?(']')
        errors.add(:base,
          I18n.t('subject_linking_error',
            scope: error_scope) + I18n.t('unclosed_bracket_within', tag: "\"#{inner_tag}\"", scope: error_scope))
      end
      # check for blank title or display name with pipes
      next unless inner_tag.include?('|')

      tag_parts = inner_tag.split('|')
      debug("validate_source: inner tag parts are #{tag_parts.inspect}")
      if tag_parts[0] =~ /^\s*$/
        errors.add(:base,
          I18n.t('subject_linking_error', scope: error_scope) + I18n.t('blank_subject_in', tag: "\"[[#{inner_tag}]]\"", scope: error_scope))
      end
      if tag_parts[1] =~ /^\s*$/
        errors.add(:base,
          I18n.t('subject_linking_error', scope: error_scope) + I18n.t('blank_text_in', tag: "\"[[#{inner_tag}]]\"", scope: error_scope))
      end
    end
    #    return errors.size > 0
  end

  ##############################################
  # All code to convert transcriptions from source
  # format to canonical xml format belongs here.
  ##############################################
  def process_source
    self.xml_text = wiki_to_xml(self, Page::TEXT_TYPE::TRANSCRIPTION) if @text_dirty

    return unless @translation_dirty

    self.xml_translation = wiki_to_xml(self, Page::TEXT_TYPE::TRANSLATION)
  end

  def wiki_to_xml(page, text_type)
    subjects_disabled = page.collection.subjects_disabled

    case text_type
    when Page::TEXT_TYPE::TRANSCRIPTION
      source_text = page.source_text
    when Page::TEXT_TYPE::TRANSLATION
      source_text = page.source_translation
    else
      source_text = ''
    end

    xml_string = String.new(source_text)
    xml_string = process_latex_snippets(xml_string)
    xml_string = clean_bad_braces(xml_string)
    xml_string = clean_script_tags(xml_string)
    xml_string = process_square_braces(xml_string) unless subjects_disabled
    xml_string = process_linewise_markup(xml_string)
    xml_string = process_line_breaks(xml_string)
    xml_string = valid_xml_from_source(xml_string)
    xml_string = update_links_and_xml(xml_string, false, text_type)
    xml_string = postprocess_xml_markup(xml_string)
    postprocess_sections
    xml_string
  end

  # remove script tags from HTML to prevent javascript injection
  def clean_script_tags(text)
    # text.gsub(/<script.*?<\/script>/m, '')
    text.gsub(%r{</?script.*?>}m, '')
  end

  BAD_SHIFT_REGEX = /\[\[([[[:alpha:]][[:blank:]]|,\(\)\-[[:digit:]]]+)\}\}/
  def clean_bad_braces(text)
    text.gsub BAD_SHIFT_REGEX, '[[\\1]]'
  end

  BRACE_REGEX = /\[\[.*?\]\]/m
  def process_square_braces(text)
    # find all the links
    wikilinks = text.scan(BRACE_REGEX)
    wikilinks.each do |wikilink_contents|
      # strip braces
      munged = wikilink_contents.sub('[[', '')
      munged = munged.sub(']]', '')

      # extract the title and display
      if munged.include? '|'
        parts = munged.split '|'
        title = parts[0]
        verbatim = parts[1]
      else
        title = munged
        verbatim = munged
      end

      title = canonicalize_title(title)

      replacement = "<link target_title=\"#{title}\">#{verbatim}</link>"
      text.sub!(wikilink_contents, replacement)
    end

    text
  end

  def remove_square_braces(text)
    new_text = text.scan(BRACE_REGEX)
    new_text.each do |results|
      changed = results
      # remove title
      changed = results.sub(/\[\[.*?\|/, '') if results.include?('|')
      changed = changed.sub('[[', '')
      changed = changed.sub(']]', '')

      text.sub!(results, changed)
    end
    text
  end

  LATEX_SNIPPET = /(\{\{tex:?(.*?):?tex\}\})/m
  def process_latex_snippets(text)
    return text unless respond_to? :tex_figures

    replacements = {}
    figures = tex_figures.to_a

    text.scan(LATEX_SNIPPET).each_with_index do |pair, i|
      with_tags = pair[0]
      contents = pair[1]

      replacements[with_tags] = "<texFigure position=\"#{i + 1}\"/>" # position attribute in acts as list starts with 1

      figure = figures[i] || TexFigure.new
      figure.source = contents unless figure.source == contents
      figures[i] = figure
    end

    self.tex_figures = figures
    replacements.each_pair do |s, r|
      text.sub!(s, r)
    end

    text
  end

  HEADER = /\s\|\s/
  SEPARATOR = /---.*\|/
  ROW = HEADER

  def process_linewise_markup(text)
    @tables = []
    @sections = []
    new_lines = []
    current_table = nil
    text.lines.each do |line|
      # first deal with any sections
      line = process_any_sections(line)
      # look for a header
      if !current_table
        if line.match(HEADER)
          line.chomp
          current_table = { header: [], rows: [], section: @sections.last }
          # fill the header
          cells = line.split(/\s*\|\s*/)
          cells.shift if line.match(/^\|/) # remove leading pipe
          current_table[:header] = cells.map { |cell_title| cell_title.sub(/^!\s*/, '') }
          heading = cells.map do |cell|
            if cell.match(/^!/)
              "<th class=\"bang\">#{cell.sub(/^!\s*/, '')}</th>"
            else
              "<th>#{cell}</th>"
            end
          end.join(' ')
          new_lines << "<table class=\"tabular\">\n<thead>\n<tr>#{heading}</tr></thead>"
        else
          # no current table, no table contents -- NO-OP
          new_lines << line
        end
      elsif line.match(SEPARATOR)
      # this is either an end or a separator
      # NO-OP
      elsif line.match(ROW)
        # remove leading and trailing delimiters
        clean_line = line.chomp.sub(/^\s*\|/, '').sub(/\|\s*$/, '')
        # fill the row
        cells = clean_line.split(/\s*\|\s*/, -1) # -1 means "don't prune empty values at the end"
        current_table[:rows] << cells
        rowline = ''
        cells.each_with_index do |cell, i|
          current_table[:header][i]
          rowline += "<td>#{cell}</td> "
        end

        new_lines << '<tbody>' if current_table[:rows].size == 1
        new_lines << "<tr>#{rowline}</tr>"
      else
        # finished the last row
        if current_table[:rows].size > 0 # only process tables with bodies
          @tables << current_table
          new_lines << '</tbody>'
        end
        new_lines << '</table>'
        current_table = nil
      end
    end

    if current_table
      # unclosed table
      @tables << current_table
      if current_table[:rows].size > 0 # only process tables with bodies
        @tables << current_table
        new_lines << '</tbody>'
      end
      new_lines << '</table>'
    end
    # do something with the table data
    new_lines.join(' ')
  end

  def process_any_sections(line)
    6.downto(2) do |depth|
      line.scan(/(={#{depth}}([^=]+)={#{depth}})/).each do |section_match|
        wiki_title = section_match[1].strip
        next unless wiki_title.length > 0

        verbatim = XmlSourceProcessor.cell_to_plaintext(wiki_title)
        safe_verbatim = verbatim.gsub('"', '&quot;')
        line = line.sub(section_match.first, "<entryHeading title=\"#{safe_verbatim}\" depth=\"#{depth}\" >#{wiki_title}</entryHeading>")
        @sections << Section.new(title: wiki_title, depth:)
      end
    end

    line
  end

  def postprocess_sections
    @sections.each do |section|
      doc = XmlSourceProcessor.cell_to_xml(section.title)
      doc.elements.each('//link') do |e|
        title = e.attributes['target_title']
        article = collection.articles.where(title:).first
        e.add_attribute('target_id', article.id.to_s) if article
      end
      section.title = XmlSourceProcessor.xml_to_cell(doc)
    end
  end

  def canonicalize_title(title)
    # kill all tags
    title = title.gsub(/<.*?>/, '')
    # linebreaks -> spaces
    title = title.gsub("\n", ' ')
    # multiple spaces -> single spaces
    title = title.gsub(/\s+/, ' ')
    # change double quotes to proper xml
    title.gsub('\"', '&quot;')
  end

  # transformations converting source mode transcription to xml
  def process_line_breaks(text)
    text = "<p>#{text}</p>"
    text = text.gsub(/\s*\n\s*\n\s*/, '</p><p>')
    text = text.gsub(/([[:word:]]+)-\r\n\s*/, '\1<lb break="no" />')
    text = text.gsub(/\r\n\s*/, '<lb/>')
    text = text.gsub(/([[:word:]]+)-\n\s*/, '\1<lb break="no" />')
    text = text.gsub(/\n\s*/, '<lb/>')
    text = text.gsub(/([[:word:]]+)-\r\s*/, '\1<lb break="no" />')
    text.gsub(/\r\s*/, '<lb/>')
  end

  def valid_xml_from_source(source)
    source ||= ''
    safe = source.gsub('&', '&amp;')
    safe.gsub!('&amp;amp;', '&amp;')
    safe.gsub!(/[^\u0009\u000A\u000D\u0020-\uD7FF\uE000-\uFFFD\u10000-\u10FFF]/, ' ')

    <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
      <page>
        #{safe}
      </page>
EOF
  end

  def update_links_and_xml(xml_string, preview_mode = false, text_type)
    # first clear out the existing links
    clear_links(text_type) unless preview_mode
    processed = ''
    # process it
    doc = REXML::Document.new xml_string
    doc.elements.each('//link') do |element|
      # default the title to the text if it's not specified
      unless (title = element.attributes['target_title'])
        title = element.text
      end
      # display_text = element.text
      display_text = ''
      element.children.each do |e|
        display_text += e.to_s
      end
      debug("link display_text = #{display_text}")
      # change the xml version of quotes back to double quotes for article title
      title = title.gsub('&quot;', '"')

      # create new blank articles if they don't exist already
      unless (article = collection.articles.where(title:).first)
        article = Article.new
        article.title = title
        article.collection = collection
        article.created_by_id = User.current_user.id if User.current_user.present?
        article.save! unless preview_mode
      end
      link_id = create_link(article, display_text, text_type) unless preview_mode
      # now update the attribute
      link_element = REXML::Element.new('link')
      element.children.each { |c| link_element.add(c) }
      link_element.add_attribute('target_title', title)
      debug("element=#{link_element.inspect}")
      debug("article=#{article.inspect}")
      link_element.add_attribute('target_id', article.id.to_s) unless preview_mode
      link_element.add_attribute('link_id', link_id.to_s) unless preview_mode
      element.replace_with(link_element)
    end
    doc.write(processed)
    processed
  end

  # handle XML-dependent post-processing
  def postprocess_xml_markup(xml_string)
    doc = REXML::Document.new xml_string
    processed = ''
    doc.elements.each('//lb') do |element|
      if element.previous_element && element.previous_sibling.node_type == :element && element.previous_element.name == 'lb'
        doc.to_s
        element.parent.elements.delete(element)
      end
    end
    doc.write(processed)
    processed
  end

  CELL_PREFIX = "<?xml version='1.0' encoding='UTF-8'?><cell>"
  CELL_SUFFIX = '</cell>'

  def self.cell_to_xml(cell)
    REXML::Document.new(CELL_PREFIX + cell.gsub('&', '&amp;') + CELL_SUFFIX)
  end

  def self.xml_to_cell(doc)
    text = ''
    doc.write(text)
    text.sub(CELL_PREFIX, '').sub(CELL_SUFFIX, '')
  end

  def self.cell_to_plaintext(cell)
    doc = cell_to_xml(cell)
    doc.each_element('.//text()') { |e| p e.text }.join
  end

  def self.cell_to_subject(cell)
    doc = cell_to_xml(cell)
    subjects = ''
    doc.elements.each('//link') do |e|
      title = e.attributes['target_title']
      subjects << title
      subjects << "\n"
    end
    subjects
  end

  def self.cell_to_category(cell)
    doc = cell_to_xml(cell)
    categories = ''
    doc.elements.each('//link') do |e|
      id = e.attributes['target_id']
      next unless id

      article = Article.find(id)
      article.categories.each do |category|
        categories << category.title
        categories << "\n"
      end
    end
    categories
  end

  ##############################################
  # Code to rename links within the text.
  # This assumes that the name change has already
  # taken place within the article table in the DB
  ##############################################
  def rename_article_links(old_title, new_title)
    title_regex =
      Regexp.escape(old_title).
        gsub('\\ ', ' '). # Regexp.escape converts ' ' to '\\ ' for some reason -- undo this
        gsub(/\s+/, '\s+') # convert multiple whitespaces into 1+n space characters

    self.source_text = rename_link_in_text(source_text, title_regex, new_title)

    # Articles don't have translations, but we still need to update pages.source_translation
    return unless has_attribute?(:source_translation) && !source_translation.nil?

    self.source_translation = rename_link_in_text(source_translation, title_regex, new_title)
  end

  def rename_link_in_text(text, title_regex, new_title)
    # handle links of the format [[Old Title|Display Text]]
    text = text.gsub(/\[\[#{title_regex}\|/, "[[#{new_title}|")
    # handle links of the format [[Old Title]]
    text.gsub(/\[\[(#{title_regex})\]\]/, "[[#{new_title}|\\1]]")
  end

  def pipe_tables_formatting(text)
    # since Pandoc Pipe Tables extension requires pipe characters at the beginning and end of each line we must add them
    # to the beginning and end of each line
    text.split("\n").map { |line| "|#{line}|" }.join("\n")
  end

  def xml_table_to_markdown_table(table_element, pandoc_format = false)
    text_table = ''

    # clean up in-cell line-breaks
    table_element.xpath('//lb').each { |n| n.replace(' ') }

    # calculate the widths of each column based on max(header, cell[0...end])
    column_count = ([table_element.xpath('//th').count] + table_element.xpath('//tr').map { |e| e.xpath('td').count }).max
    column_widths = {}
    1.upto(column_count) do |column_index|
      longest_cell = table_element.xpath("//tr/td[position()=#{column_index}]").map { |e| e.text.length }.max || 0
      corresponding_heading = table_element.xpath("//th[position()=#{column_index}]").first
      heading_length = corresponding_heading.nil? ? 0 : corresponding_heading.text.length
      column_widths[column_index] = [longest_cell, heading_length].max
    end

    # print the header as markdown
    cell_strings = []
    table_element.xpath('//th').each_with_index do |e, i|
      cell_strings << e.text.rjust(column_widths[i + 1], ' ')
    end
    text_table << cell_strings.join(' | ') << "\n"

    # print the separator
    text_table << column_count.times.map { |i| ''.rjust(column_widths[i + 1], '-') }.join(' | ') << "\n"

    # print each row as markdown
    table_element.xpath('//tr').each do |row_element|
      text_table << row_element.xpath('td').map do |e|
        width = 80 # default for hand-coded tables
        index = e.path.match(/.*td\[(\d+)\]/)
        if index
          width = column_widths[index[1].to_i] || 80
        else
          width = column_widths.values.first
        end
        e.text.rjust(width, ' ')
      end.join(' | ') << "\n"
    end
    text_table = pipe_tables_formatting(text_table) if pandoc_format

    text_table
  end

  def debug(msg)
    logger.debug("DEBUG: #{msg}")
  end

end
