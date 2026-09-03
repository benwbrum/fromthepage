# Pads ragged HTML tables so every row exposes the same number of cells.
#
# Transcribers can build TEI `<table>`/`<row>`/`<cell>` structures where rows
# have differing cell counts. When Chrome renders those to a tagged PDF the
# resulting structure tree has rows with different numbers of `TD`/`TH`
# children, which fails Acrobat's "Regularity" accessibility check
# ("Tables must contain the same number of columns in each row").
#
# This normalises the rendered export HTML (not the on-screen transcription):
# for each table it finds the widest row and appends empty cells to the
# shorter ones. The padding cells carry a non-breaking space because Chrome
# omits truly empty cells from the PDF structure tree.
class Work::Export::TableRegularizer
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
    doc.css('table').each { |table| regularize(table) }
    doc.to_html
  end

  private

  def regularize(table)
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
