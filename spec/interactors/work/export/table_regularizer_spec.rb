require 'spec_helper'

describe Work::Export::TableRegularizer do
  def cell_counts(html)
    Nokogiri::HTML5.parse(html).css('table tr').map do |row|
      row.element_children.count { |c| %w[td th].include?(c.name) }
    end
  end

  it 'returns blank input unchanged' do
    expect(described_class.call('')).to eq('')
    expect(described_class.call(nil)).to be_nil
  end

  it 'pads short rows so every row has the widest row\'s cell count' do
    html = <<~HTML
      <table>
        <tr><th>A</th><th>B</th><th>C</th></tr>
        <tr><td>1</td><td>2</td></tr>
        <tr><td>3</td></tr>
      </table>
    HTML

    expect(cell_counts(described_class.call(html))).to eq([3, 3, 3])
  end

  it 'fills padding cells with a non-breaking space so Chrome keeps them tagged' do
    html = '<table><tr><td>a</td><td>b</td></tr><tr><td>c</td></tr></table>'

    padded = Nokogiri::HTML5.parse(described_class.call(html)).css('tr').last.css('td').last
    expect(padded.text).to eq(" ")
  end

  it 'leaves already-regular tables untouched' do
    html = '<table><tr><td>a</td><td>b</td></tr><tr><td>c</td><td>d</td></tr></table>'

    expect(cell_counts(described_class.call(html))).to eq([2, 2])
  end

  it 'accounts for colspan when measuring row width' do
    html = <<~HTML
      <table>
        <tr><td colspan="3">wide</td></tr>
        <tr><td>a</td></tr>
      </table>
    HTML

    expect(cell_counts(described_class.call(html))).to eq([1, 3])
  end

  it 'skips tables that use rowspan rather than risk a worse layout' do
    html = <<~HTML
      <table>
        <tr><td rowspan="2">a</td><td>b</td></tr>
        <tr><td>c</td></tr>
      </table>
    HTML

    expect(cell_counts(described_class.call(html))).to eq([2, 1])
  end

  it 'regularizes multiple tables independently' do
    html = <<~HTML
      <table id="one"><tr><td>a</td><td>b</td></tr><tr><td>c</td></tr></table>
      <table id="two"><tr><td>x</td></tr><tr><td>y</td></tr></table>
    HTML

    doc = Nokogiri::HTML5.parse(described_class.call(html))
    expect(doc.css('#one tr').map { |r| r.css('td').count }).to eq([2, 2])
    expect(doc.css('#two tr').map { |r| r.css('td').count }).to eq([1, 1])
  end
end
