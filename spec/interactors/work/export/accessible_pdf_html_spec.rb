require 'spec_helper'

describe Work::Export::AccessiblePdfHtml do
  def doc(html)
    Nokogiri::HTML5.parse(described_class.call(html))
  end

  def cell_counts(html)
    doc(html).css('table tr').map do |row|
      row.element_children.count { |c| %w[td th].include?(c.name) }
    end
  end

  it 'returns blank input unchanged' do
    expect(described_class.call('')).to eq('')
    expect(described_class.call(nil)).to be_nil
  end

  describe 'flattening anchors' do
    it 'replaces a subject link with its visible text' do
      html = '<p>He met <a href="http://example.com/article/show?article_id=5" title="Mr Moon">Mr Moon</a> today.</p>'

      result = doc(html)
      expect(result.css('a')).to be_empty
      expect(result.css('p').text).to eq('He met Mr Moon today.')
    end

    it 'keeps nested markup inside a flattened link' do
      html = '<p><a href="/x">the <i>Old</i> House</a></p>'

      result = doc(html)
      expect(result.css('a')).to be_empty
      expect(result.css('p i').text).to eq('Old')
      expect(result.css('p').text).to eq('the Old House')
    end
  end

  describe 'unwrapping line-break spans' do
    it 'replaces a line-break span with its single space' do
      html = '<p>first line<span class="line-break"> </span>second line</p>'

      result = doc(html)
      expect(result.css('span.line-break')).to be_empty
      expect(result.css('p').text).to eq('first line second line')
    end

    it 'removes an empty (break="no") line-break span so the halves rejoin' do
      html = '<p>rejoi<span class="line-break"></span>ned</p>'

      result = doc(html)
      expect(result.css('span.line-break')).to be_empty
      expect(result.css('p').text).to eq('rejoined')
    end

    it 'leaves other spans alone' do
      html = '<p>see <span class="unclear">[word]</span> here</p>'

      expect(doc(html).css('span.unclear').text).to eq('[word]')
    end
  end

  describe 'regularizing tables' do
    it "pads short rows to the widest row's cell count" do
      html = <<~HTML
        <table>
          <tr><th>A</th><th>B</th><th>C</th></tr>
          <tr><td>1</td><td>2</td></tr>
          <tr><td>3</td></tr>
        </table>
      HTML

      expect(cell_counts(html)).to eq([3, 3, 3])
    end

    it 'fills padding cells with a non-breaking space so Chrome keeps them tagged' do
      html = '<table><tr><td>a</td><td>b</td></tr><tr><td>c</td></tr></table>'

      padded = doc(html).css('tr').last.css('td').last
      expect(padded.text).to eq(" ")
    end

    it 'leaves already-regular tables untouched' do
      html = '<table><tr><td>a</td><td>b</td></tr><tr><td>c</td><td>d</td></tr></table>'

      expect(cell_counts(html)).to eq([2, 2])
    end

    it 'accounts for colspan when measuring row width' do
      html = '<table><tr><td colspan="3">wide</td></tr><tr><td>a</td></tr></table>'

      expect(cell_counts(html)).to eq([1, 3])
    end

    it 'skips tables that use rowspan rather than risk a worse layout' do
      html = <<~HTML
        <table>
          <tr><td rowspan="2">a</td><td>b</td></tr>
          <tr><td>c</td></tr>
        </table>
      HTML

      expect(cell_counts(html)).to eq([2, 1])
    end
  end

  it 'applies every transform in one pass' do
    html = <<~HTML
      <p>1845 Feby 22 <a href="/article/show?article_id=1">Mr Moon</a> has<span class="line-break"> </span>shingles</p>
      <table><tr><th>x</th><th>y</th></tr><tr><td>1</td></tr></table>
    HTML

    result = doc(html)
    expect(result.css('a')).to be_empty
    expect(result.css('span.line-break')).to be_empty
    expect(result.css('p').text).to eq('1845 Feby 22 Mr Moon has shingles')
    expect(result.css('table tr').map { |r| r.css('td, th').count }).to eq([2, 2])
  end
end
