class Work::Export::Lib::Utils
  LINEBREAK_ELEMENT = "\\\\{}\n"
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

    text.gsub(/([\\\{\}\$\&\%\#\_\~\^])/) { replacements[$1] }
  end

  def self.xml_to_latex(page:, xml_text:, preserve_lb: true, flatten_links: false)
    doc = REXML::Document.new(xml_text)
    page_doc = doc.root

    page_doc.elements.map { |element| process_element(page, element, preserve_lb, flatten_links) }.join
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
      "#{content}#{LINEBREAK_ELEMENT}"
    when 'lb'
      if element.attributes['break'] == 'no'
        content = LINEBREAK_ELEMENT
        content = "-#{LINEBREAK_ELEMENT}"
      else
        preserve_lb ? "#{LINEBREAK_ELEMENT}" : ' '
      end
    when 'b'
      "\\textbf{#{content}}"
    when 'i', 'em'
      "\\textit{#{content}}"
    when 'u'
      "\\underline{#{content}}"
    when 's'
      "\\sout{#{content}}"
    when 'hi'
      process_hi(element, content)
    when 'sup'
      "\\textsuperscript{#{content}}"
    when 'table'
      process_table(page, element, preserve_lb, flatten_links)
    when 'tr', 'row'
      element.elements.to_a('th|td').map { |td| process_element(page, td, preserve_lb, flatten_links) }.join(' & ') + " \\\\\n"
    when 'td'
      content
    when 'link'
      process_links(element, content, flatten_links)
    when 'add', 'ins'
      "\\textsuperscript{\\underline{#{content}}}"
    when 'abbr'
      expan = element.attributes['expan']

      # TODO: PDF and DOCX. Add lua filter to handle HTML to have tooltips
      "\\underline{\\textit{#{expan}}}\\{#{content}\\}"
    when 'expan'
      abbr = element.attributes['abbr'] || element.attributes['orig']

      # TODO: PDF and DOCX. Add lua filter to handle HTML to have tooltips
      "\\underline{\\textit{#{content}}}\\{#{abbr}\\}"
    when 'reg'
      orig = element.attributes['orig']

      # TODO: PDF and DOCX. Add lua filter to handle HTML to have tooltips
      "\\underline{\\textit{#{content}}}\\{#{orig}\\}"
    when 'footnote'
      "\\footnote{#{content}}"
    when 'head'
      "#{LINEBREAK_ELEMENT}\\textbf{#{content}}#{LINEBREAK_ELEMENT}"
    when 'entryHeading'
      depth = element.attributes['depth'].to_i
      title = element.attributes['title']
      case depth
      when 2
        output = "\\underline{\\textbf{#{content}}}"
      when 3
        output = "\\textbf{#{content}}"
      when 4
        output = "\\underline{#{content}}"
      when 5
        output = "\\textit{#{content}}"
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
      "\\textit{[#{content}]}"
    when 'cb', 'pb', 'marginalia'
      process_breaks(element, content)
    when 'catchword'
      "\\{#{content}\\}"
    when 'gap'
      '\textit{[...]}'
    when 'stamp'
      stamp_type = element.attributes['type'] || ''
      stamp_text = stamp_type.present? ? "#{stamp_type&.titleize} " : ''
      stamp_text += 'Stamp'

      "\\textit{\\{#{stamp_text}\\}}"
    when 'strike', 'del'
      "\\sout{#{content}}"
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

    # Use paragraph columns with text wrapping for better handling of wide content
    # Calculate appropriate column width based on number of columns
    # Tables should always have at least one column
    column_width = "#{(0.9 / column_count).round(2)}\\linewidth"
    column_format = '@{}' + ("p{#{column_width}} " * column_count).strip + '@{}'

    # Determine if we need landscape mode and/or smaller font
    use_landscape = column_count >= 8
    use_small_font = column_count >= 6

    latex = "#{LINEBREAK_ELEMENT}"

    # Add landscape environment for very wide tables (8+ columns)
    latex += "\\begin{landscape}\n" if use_landscape

    # Use smaller font for tables with many columns (6+ columns)
    latex += "\\small\n" if use_small_font && !use_landscape
    latex += "\\footnotesize\n" if use_landscape

    latex += "\\begin{longtable}[]{#{column_format}}\n"

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

    # Close landscape environment if used
    latex += "\\end{landscape}\n" if use_landscape

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

    "\\href{#{href_value}}{#{content}}"
  end

  def self.process_hi(hi_element, content)
    case hi_element.attributes['rend']
    when 'sup'
      "\\textsuperscript{#{content}}"
    when 'sub'
      "\\textsubscript{#{content}}"
    when 'underline'
      "\\underline{#{content}}"
    when 'italics'
      "\\textit{#{content}}"
    when 'bold'
      "\\textbf{#{content}}"
    when 'str'
      "\\sout{#{content}}"
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
end
