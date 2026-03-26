class Work::Export::Lib::Utils
  LINEBREAK_ELEMENT = "\\\\{}\n"
  COLUMN_THRESHOLD = 7
  HR_ELEMENT = '\{\{hr\}\}'
  BREAK_TEXT = {
    'cb' => 'column',
    'pb' => 'page break'
  }
  TABLE_CONVENTIONS_MAP = {
    'row' => 'tr',
    'cell' => 'td'
  }
  HTML_ENTITIES = [
    '&amp;',
    '&lt;',
    '&gt;',
    '&quot;',
    '&#39;',
    '&nbsp;'
  ]

  def self.latex_escape(text)
    return '' if text.blank?

    replacements = {
      '\\' => '\\textbackslash{}',
      '{'  => '\\{',
      '}'  => '\\}',
      '$'  => '\\$',
      '&'  => '\\&',
      '%'  => '\\%',
      '#'  => '\\#',
      '_'  => '\\_',
      '~'  => '\\textasciitilde{}',
      '^'  => '\\textasciicircum{}'
    }

    command_regex = /\\[a-zA-Z]+(?:\{[^}]*\})?/

    text.gsub(/#{command_regex}|./m) do |chunk|
      if chunk.match?(command_regex)
        chunk
      else
        replacements[chunk] || chunk
      end
    end
  end

  def self.xml_to_latex(page:, xml_text:, preserve_lb: true, flatten_links: false)
    doc = REXML::Document.new(xml_text)
    page_doc = doc.root

    tex_string = page_doc.elements.map { |element| process_element(page, element, preserve_lb, flatten_links) }.join
    tex_string.sub(/(#{Regexp.escape(LINEBREAK_ELEMENT)}){2}\z/, '')
  end

  def self.process_element(page, element, preserve_lb, flatten_links)
    content = element.children.map do |child|
      if child.is_a?(REXML::Element)
        process_element(page, child, preserve_lb, flatten_links)
      else
        latex_escape(child.to_s)
      end
    end.join

    case element.name
    when 'p'
      stripped_content = content.sub(/#{Regexp.escape(LINEBREAK_ELEMENT)}\z/, '')
      "#{stripped_content}#{LINEBREAK_ELEMENT}#{LINEBREAK_ELEMENT}"
    when 'lb'
      if element.attributes['break'] == 'no'
        content = LINEBREAK_ELEMENT
        content = "-#{LINEBREAK_ELEMENT}"
      else
        preserve_lb ? "#{LINEBREAK_ELEMENT}" : ' '
      end
    when 'b'
      wrap_inline_with_linebreak(['textbf'], content)
    when 'i', 'em'
      wrap_inline_with_linebreak(['textit'], content)
    when 'u'
      wrap_inline_with_linebreak(['underline'], content)
    when 's'
      wrap_inline_with_linebreak(['sout'], content)
    when 'hi'
      process_hi(element, content)
    when 'sup'
      wrap_inline_with_linebreak(['textsuperscript'], content)
    when 'table'
      process_table(page, element, preserve_lb, flatten_links)
    when 'tr', 'row'
      element.elements.to_a('th|td').map { |td| process_element(page, td, preserve_lb, flatten_links) }.join(' & ') + " \\\\\n"
    when 'td'
      content
    when 'link'
      process_links(element, content, flatten_links)
    when 'add', 'ins'
      wrap_inline_with_linebreak(['textsuperscript', 'underline'], content)
    when 'abbr'
      expan = element.attributes['expan']

      # NOTE: No need to wrap_inline_with_linebreak. We are not expecting
      # an `abbr` tag to have linebreaks in it.
      # TODO: PDF and DOCX. Add lua filter to handle HTML to have tooltips
      "\\underline{\\textit{#{expan}}}\\{#{content}\\}"
    when 'expan'
      abbr = element.attributes['abbr'] || element.attributes['orig']

      # NOTE: No need to wrap_inline_with_linebreak. We are not expecting
      # an `expan` tag to have linebreaks in it.
      # TODO: PDF and DOCX. Add lua filter to handle HTML to have tooltips
      "\\underline{\\textit{#{content}}}\\{#{abbr}\\}"
    when 'reg'
      orig = element.attributes['orig']

      # NOTE: No need to wrap_inline_with_linebreak. We are not expecting
      # a `reg` tag to have linebreaks in it.
      # TODO: PDF and DOCX. Add lua filter to handle HTML to have tooltips
      "\\underline{\\textit{#{content}}}\\{#{orig}\\}"
    when 'footnote'
      wrap_inline_with_linebreak(['footnote'], content)
    when 'head'
      "#{LINEBREAK_ELEMENT}\\textbf{#{content}}#{LINEBREAK_ELEMENT}"
    when 'entryHeading'
      depth = element.attributes['depth'].to_i
      title = element.attributes['title']
      case depth
      when 2
        output  = wrap_inline_with_linebreak(['underline', 'textbf'], content)
      when 3
        output  = wrap_inline_with_linebreak(['textbf'], content)
      when 4
        output  = wrap_inline_with_linebreak(['underline'], content)
      when 5
        output  = wrap_inline_with_linebreak(['textit'], content)
      else
        output = content
      end

      if title.present?
        # TODO: PDF and DOCX. Add lua filter to handle HTML to have tooltips
        "#{output}\\{#{title}\\}"
      else
        output
      end
    when 'figure'
      process_figure(element, content)
    when 'unclear'
      wrap_inline_with_linebreak(['textit'], content, decorator: :brackets)
    when 'cb', 'pb', 'marginalia'
      # NOTE: No need to wrap_inline_with_linebreak. We are not expecting
      # `cb, pb, or marginalia` tags to have linebreaks.
      process_breaks(element, content)
    when 'catchword'
      "\\{#{content}\\}"
    when 'gap'
      '\textit{[...]}'
    when 'stamp'
      stamp_type = element.attributes['type'] || ''
      stamp_text = stamp_type.present? ? "#{stamp_type&.titleize} " : ''
      stamp_text += 'Stamp'

      # NOTE: No need to wrap_inline_with_linebreak. We are not expecting
      # a `stamp` tag to have linebreaks in it.
      "\\textit{\\{#{stamp_text}\\}}"
    when 'strike', 'del'
      wrap_inline_with_linebreak(['sout'], content)
    when 'texFigure'
      position = element.attributes['position']
      tex_figure = page.tex_figures.find_by(position: position)
      "#{tex_figure.source}\n"
    else
      latex_escape(content)
    end
  end

  def self.process_table(page, table_element, preserve_lb, flatten_links)
    TABLE_CONVENTIONS_MAP.each do |key, value|
      table_element.elements.each(".//#{key}") do |el|
        el.name = value
      end
    end

    all_rows = []
    all_rows += table_element.elements['thead'].elements.to_a('tr') if table_element.elements['thead']
    all_rows += table_element.elements['tbody'].elements.to_a('tr') if table_element.elements['tbody']

    column_count = all_rows.map { |tr| tr.elements.count }.max
    column_format = '@{}' + ('l ' * column_count).strip + '@{}'

    latex = "#{LINEBREAK_ELEMENT}\n"

    if column_count > COLUMN_THRESHOLD
      latex += "\\begin{rotatetable}\n"
    end

    latex += "\\begin{longtable}[\\textwidth]{#{column_format}}\n"
    if table_element.elements['thead']
      latex += "\\toprule\n"

      table_element.elements['thead'].elements.each do |th|
        latex += process_element(page, th, preserve_lb, flatten_links)
      end
      latex += "\\midrule\\noalign{}\n"
    end

    if table_element.elements['tbody']
      table_element.elements['tbody'].elements.each do |tr|
        latex += process_element(page, tr, preserve_lb, flatten_links)
      end
    end

    latex += "\\bottomrule\\noalign{}\n"
    latex += "\\end{longtable}\n"

    if column_count > COLUMN_THRESHOLD
      latex += "\\end{rotatetable}\n"
    end

    latex
  end

  def self.process_links(link_element, content, flatten_links)
    article_id = link_element.attributes['target_id']
    if flatten_links == :jekyll
      href_value = "../subjects/#{article_id}"
    elsif flatten_links
      href_value = "#article-#{article_id}"
    else
      href_value = Rails.application.routes.url_helpers.article_show_path(
        article_id: article_id
      )
    end

    parts = content.split(LINEBREAK_ELEMENT)

    parts.map do |part|
      " \\href{#{href_value}}{#{part}} "
    end.join(LINEBREAK_ELEMENT)
  end

  def self.process_hi(hi_element, content)
    case hi_element.attributes['rend']
    when 'sup'
      wrap_inline_with_linebreak(['textsuperscript'], content)
    when 'sub'
      wrap_inline_with_linebreak(['textsubscript'], content)
    when 'underline'
      wrap_inline_with_linebreak(['underline'], content)
    when 'italics'
      wrap_inline_with_linebreak(['textit'], content)
    when 'bold'
      wrap_inline_with_linebreak(['textbf'], content)
    when 'str'
      wrap_inline_with_linebreak(['sout'], content)
    else
      content
    end
  end

  def self.process_figure(figure_element, content)
    figure_type = figure_element.attributes['rend'] || figure_element.attributes['type']

    if figure_type == 'hr'
      HR_ELEMENT
    else
      "#{content}\\{#{(figure_type || figure_element.name).titleize}\\}"
    end
  end

  def self.process_breaks(break_element, content)
    if break_element.name == 'marginalia'
      content = "\\{#{content}\\}"
    else
      break_text = BREAK_TEXT[break_element.name]
      column_number = break_element.attributes['n']
      column_text = column_number.present? ? " #{column_number}" : ''

      content = "\\{#{break_text}#{column_text}\\}"
      content = "#{LINEBREAK_ELEMENT}\\textit{#{content}}#{LINEBREAK_ELEMENT}"
    end

    content
  end

  def self.html_unescape(html_string)
    unescaped = html_string.dup

    loop do
      new_unescaped = CGI.unescapeHTML(unescaped)

      break if new_unescaped == unescaped

      unescaped = new_unescaped
    end

    unescaped
  end

  def self.wrap_inline_with_linebreak(wrappers, content, decorator: nil)
    content.split(LINEBREAK_ELEMENT).map do |part|
      wrapped = part
      wrappers.reverse.each do |w|
        if decorator == :brackets
          wrapped = "\\#{w}{[#{wrapped}]}"
        else
          wrapped = "\\#{w}{#{wrapped}}"
        end
      end
      wrapped
    end.join(LINEBREAK_ELEMENT)
  end
end
