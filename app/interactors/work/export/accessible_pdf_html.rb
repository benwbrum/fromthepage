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
# It also pads ragged tables so every row exposes the same number of cells,
# which Acrobat's table "Regularity" check requires.
class Work::Export::AccessiblePdfHtml
  PAD_CONTENT = "\u00A0" # non-breaking space: renders blank but is not "empty"

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
    doc.css('table').each { |table| regularize_table(table) }
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

  def cells(row)
    row.element_children.select { |child| %w[td th].include?(child.name) }
  end
end
