class Xml::Lib::SourceProcessor::Base
  def self.new(object)
    return super unless self == Base

    klass = case object
            when Article
              Xml::Lib::SourceProcessor::Article
            when Page
              Page::Lib::XmlSourceProcessor
            else
              raise ArgumentError, "Unsupported object type: #{object.class}"
            end

    klass.new(object)
  end

  private

  BAD_SHIFT_REGEX = /\[\[([[[:alpha:]][[:blank:]]|,\(\)\-[[:digit:]]]+)\}\}/
  def clean_bad_braces(text)
    text.gsub BAD_SHIFT_REGEX, "[[\\1]]"
  end

  SCRIPT_TAG_REGEX = /<\/?script.*?>/m
  def clean_script_tags(text)
    text.gsub(SCRIPT_TAG_REGEX, '')
  end

  BRACE_REGEX = /\[\[.*?\]\]/m
  def process_square_braces(text)
    # Find all the links
    wikilinks = text.scan(BRACE_REGEX)
    wikilinks.each do |wikilink_contents|
      # Strip braces
      munged = wikilink_contents.sub('[[', '')
      munged = munged.sub(']]', '')

      # Extract the title and display
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

  def canonicalize_title(title)
    # kill all tags
    title = title.gsub(/<.*?>/, '')
    # linebreaks -> spaces
    title = title.gsub(/\n/, ' ')
    # multiple spaces -> single spaces
    title = title.gsub(/\s+/, ' ')
    # change double quotes to proper xml
    title = title.gsub(/\"/, '&quot;')

    title
  end

  HEADER = /\s\|\s/
  SEPARATOR = /---.*\|/
  ROW = HEADER
  def process_linewise_markup(text)
    last_section = nil
    current_table = nil
    new_lines = []

    text.lines.each do |line|
      line, cur_section = process_any_sections(line)
      last_section = cur_section unless cur_section.nil?

      if current_table.nil?
        if line.match(HEADER)
          line.chomp
          current_table = { header: [], rows: [], section: last_section }
          # Fill the header
          cells = line.split(/\s*\|\s*/)
          # Remove leading pipe
          cells.shift if line.match(/^\|/)
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
          # No current table, no table contents -- NO-OP
          new_lines << line
        end
      else
        # This is either an end or a separator
        if line.match(ROW)
          # Remove leading and trailing delimiters
          clean_line = line.chomp.sub(/^\s*\|/, '').sub(/\|\s*$/, '')
          # Fill the row, -1 means "don't prune empty values at the end"
          cells = clean_line.split(/\s*\|\s*/, -1)
          current_table[:rows] << cells
          rowline = ''
          cells.each do |cell|
            rowline += "<td>#{cell}</td> "
          end
          new_lines << '<tbody>' if current_table[:rows].size == 1
          new_lines << "<tr>#{rowline}</tr>"
        elsif !line.match(SEPARATOR)
          # Finished the last row
          # only process tables with bodies
          new_lines << '</tbody>' unless current_table[:rows].empty?
          new_lines << '</table><lb/>'
          current_table = nil
        end
        # else
        # NO-OP
      end
    end

    if current_table.present?
      # Unclosed table
      # only process tables with bodies
      new_lines << '</tbody>' unless current_table[:rows].empty?
      new_lines << '</table><lb/>'
    end

    # do something with the table data
    new_lines.join(' ')
  end

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

    safe = source.gsub /\&/, '&amp;'
    safe.gsub! /\&amp;amp;/, '&amp;'
    safe.gsub! /[^\u0009\u000A\u000D\u0020-\uD7FF\uE000-\uFFFD\u10000-\u10FFFF]/, ' '

    <<~EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <page>
        #{safe}
      </page>
    EOF
  end
end
