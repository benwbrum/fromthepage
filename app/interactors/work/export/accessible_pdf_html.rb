# Prepares the rendered export HTML so headless Chrome produces a clean,
# screen-reader-friendly tagged PDF for the "accessible PDF" (reading copy)
# download.
#
# Chrome/Skia tags every inline break in the text flow as its own `NonStruct`
# marked-content run. Transcription HTML is dense with inline elements - a
# `<span class="line-break">` per source line, an `<a>` per subject link - so
# each paragraph shatters into dozens of fragments, which Windows Narrator in
# particular fails to read (it falls back to announcing only the link URLs).
# This collapses the fragments that a reading copy does not need:
#
#   * subject / wiki links become their visible text. The links resolve on the
#     live site; a printed reading copy cannot follow them, and every link
#     annotation without alt text makes AT read the raw URL.
#   * `<span class="line-break">` becomes the whitespace it carries. A reading
#     copy reflows; diplomatic line-by-line layout belongs to other editions.
#
# It then repairs the two things a screen reader otherwise cannot recover from
# the transcription markup - author deletions and unmarked table headers - and
# pads ragged tables so every row exposes the same number of cells, which
# Acrobat's table "Regularity" check requires.
#
# None of it rewrites the transcription: the words on the page are still the
# words that were transcribed. The one visible change is that a header row the
# parser invented stops being drawn as a header, because it never was one.
class Work::Export::AccessiblePdfHtml
  PAD_CONTENT = "\u00A0" # non-breaking space: renders blank but is not "empty"

  # Tags a transcriber can use to mark text the author struck out. `<hi
  # rend="str">` arrives here as `<strike>`; `<s>` and `<del>` can be typed
  # into the transcription directly.
  DELETION_TAGS = %w[strike s del].freeze
  DELETION_SELECTOR = DELETION_TAGS.join(', ').freeze

  # `process_linewise_markup` marks a cell the transcriber explicitly declared
  # as a header (a `!`-prefixed wiki cell) with this class. A `<thead>` whose
  # cells carry no `bang` is one the parser invented from the first data row.
  DECLARED_HEADER_CLASS = 'bang'.freeze

  # 1x1 fully transparent GIF. An `<img alt="...">` is the only way to attach
  # alternate text that Chrome carries into the PDF structure tree - it ignores
  # `aria-label` on a table and `summary` entirely - so a description that must
  # not disturb the printed page rides on a pixel nobody can see.
  TRANSPARENT_PIXEL = 'data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACwAAAAAAQABAAACAkQBADs='.freeze
  INVISIBLE_STYLE = 'width:1px;height:1px;display:block;margin:0;border:0'.freeze

  def self.call(html)
    new(html).call
  end

  def initialize(html)
    @html = html
  end

  def call
    return @html if @html.blank?

    doc = Nokogiri::HTML5.parse(@html)
    flatten_anchors(doc)
    unwrap_line_breaks(doc)
    annotate_deletions(doc)

    doc.css('table').each do |table|
      regularize_table(table)
      resolve_table_headers(table)
      tag_headerless_table(table)
    end

    doc.to_html
  end

  private

  # Replace every <a> with its own children, dropping the link but keeping the
  # words. In this pipeline anchors are always subject links.
  def flatten_anchors(doc)
    doc.css('a').each { |anchor| anchor.replace(anchor.children) }
  end

  # Replace each line-break span with the exact whitespace it holds so the text
  # on either side merges into one run. A normal line break carries a single
  # space; a `break="no"` (word split across lines) span is empty and is simply
  # removed so the halves rejoin.
  def unwrap_line_breaks(doc)
    doc.css('span.line-break').each do |span|
      text = span.text
      if text.empty?
        span.remove
      else
        span.replace(Nokogiri::XML::Text.new(text, span.document))
      end
    end
  end

  # A line through a word is pure visual styling: Chrome drops `<strike>`,
  # `<s>` and `<del>` from the structure tree, so AT reads struck words as
  # ordinary text and a listener never learns the author cut them.
  #
  # `role="img"` plus `aria-label` is the one hook Chrome does export - it
  # becomes a `/Figure` carrying `/Alt`, so the deletion is announced as
  # "struck through: <words>" while the page still shows the words with a line
  # through them.
  def annotate_deletions(doc)
    doc.css(DELETION_SELECTOR).each do |node|
      # An outer deletion already labels everything inside it, and a struck
      # table would be swallowed whole by the figure's alternate text.
      next if node.ancestors(DELETION_SELECTOR).any?
      next if node.at_css('table')

      words = node.text.gsub(/\s+/, ' ').strip
      next if words.empty?

      node['role'] = 'img'
      node['aria-label'] = I18n.t('export.accessible_pdf.struck_through', text: words)
    end
  end

  def regularize_table(table)
    rows = table.css('tr').to_a
    return if rows.empty?

    # Rowspans would make a naive per-row cell count wrong; leave those tables
    # untouched rather than risk making the layout worse.
    return if rows.any? { |row| cells(row).any? { |c| c['rowspan'].to_i > 1 } }

    widths = rows.map { |row| cells(row).sum { |c| [c['colspan'].to_i, 1].max } }
    target = widths.max
    return if target.to_i.zero?

    rows.each_with_index do |row, index|
      (target - widths[index]).times do
        cell = row.document.create_element('td')
        cell.content = PAD_CONTENT
        row.add_child(cell)
      end
    end
  end

  # FromThePage's wiki table syntax only recognises a header row when the cells
  # are `!`-prefixed. When they are not, `process_linewise_markup` still turns
  # the table's *first data row* into a `<thead>` of `<th>`s - so a screen
  # reader announces "Friday March 7" as the column header of every date below
  # it, which is worse than no header at all.
  #
  # Demote a header row nobody declared, and give the headers that were
  # declared an explicit scope so Chrome emits the per-cell `/Headers`
  # association that makes AT read "Date: Friday March 21" instead of "21".
  def resolve_table_headers(table)
    header_row = table.at_css('thead > tr')
    demote_header_row(table, header_row) if header_row && !declared_header?(header_row)

    table.css('th').each { |th| th['scope'] ||= scope_for(th) }
  end

  def declared_header?(row)
    cells(row).any? { |cell| cell['class'].to_s.split.include?(DECLARED_HEADER_CLASS) }
  end

  def demote_header_row(table, header_row)
    cells(header_row).each { |cell| cell.name = 'td' }

    body = table.at_css('tbody')
    if body
      first = body.element_children.first
      first ? first.add_previous_sibling(header_row) : body.add_child(header_row)
    end

    thead = table.at_css('thead')
    thead.remove if thead && thead.element_children.empty?
  end

  # A row of nothing but `<th>` heads its columns; a lone `<th>` beginning a row
  # of `<td>`s heads that row.
  def scope_for(th)
    row_cells = th.parent ? cells(th.parent) : [th]
    return 'col' if row_cells.all? { |cell| cell.name == 'th' }

    row_cells.first == th ? 'row' : 'col'
  end

  # A table with no `<th>` at all - because the transcriber never declared one,
  # or because the invented header row was just demoted - needs two things.
  #
  # First, `role="table"`: Chrome reads a header-less table as a *layout* table
  # and flattens every row and cell to `NonStruct`, losing table navigation
  # altogether. It happens to keep the tagging when the cells have visible
  # borders, as the export stylesheet gives them, but saying so outright does
  # not depend on how the cells are styled.
  #
  # Second, a description: a screen reader now reaches bare cells with nothing
  # to anchor them, so state the shape of the table and why the headers are
  # missing. It rides on an invisible pixel, leaving the transcription itself
  # exactly as written.
  def tag_headerless_table(table)
    return if table.at_css('th')

    rows = table.css('tr')
    return if rows.empty?

    table['role'] ||= 'table'

    columns = rows.map { |row| cells(row).sum { |c| [c['colspan'].to_i, 1].max } }.max
    return if columns.to_i.zero?

    description = table.document.create_element(
      'img',
      src: TRANSPARENT_PIXEL,
      alt: I18n.t('export.accessible_pdf.table_without_headers', rows: rows.size, columns: columns),
      style: INVISIBLE_STYLE
    )

    table.add_previous_sibling(description)
  end

  def cells(row)
    row.element_children.select { |child| %w[td th].include?(child.name) }
  end
end
