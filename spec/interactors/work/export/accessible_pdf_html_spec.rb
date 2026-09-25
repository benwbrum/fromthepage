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
      expect(padded.text).to eq("\u00A0")
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

  describe 'announcing author deletions' do
    # Chrome drops <strike>/<s>/<del> from the PDF structure tree entirely, so
    # role="img" + aria-label (which it exports as a /Figure with /Alt) is the
    # only way a screen reader learns the author cut the words.
    %w[strike s del].each do |tag|
      it "labels <#{tag}> so a screen reader announces the deletion" do
        result = doc("<p>Saturday 1<#{tag}>8</#{tag}>th Meeting</p>")

        struck = result.at_css(tag)
        expect(struck['role']).to eq('img')
        expect(struck['aria-label']).to eq('struck through: 8')
      end
    end

    it 'keeps the struck words visible and struck through' do
      result = doc('<p>a <strike>gone</strike> b</p>')

      expect(result.css('strike').text).to eq('gone')
      expect(result.css('p').text).to eq('a gone b')
    end

    it 'collapses line breaks and nested markup into the label' do
      html = '<p><strike>20th Another Fair<span class="line-break"> </span>cold ' \
             '<sup>wood</sup> day</strike></p>'

      expect(doc(html).at_css('strike')['aria-label'])
        .to eq('struck through: 20th Another Fair cold wood day')
    end

    it 'labels only the outermost of nested deletions' do
      result = doc('<p><strike>outer <del>inner</del></strike></p>')

      expect(result.at_css('strike')['aria-label']).to eq('struck through: outer inner')
      expect(result.at_css('del')['aria-label']).to be_nil
    end

    it 'leaves an empty deletion alone' do
      result = doc('<p><strike></strike></p>')

      expect(result.at_css('strike')['role']).to be_nil
    end

    it 'does not swallow a struck table into alternate text' do
      result = doc('<del><table><tr><td>a</td></tr></table></del>')

      expect(result.at_css('del')['role']).to be_nil
      expect(result.at_css('table')).to be_present
    end
  end

  describe 'table headers' do
    # process_linewise_markup marks a cell the transcriber declared with `!` as
    # <th class="bang">. A <thead> with no bang is one it invented from the
    # first data row.
    let(:invented) do
      <<~HTML
        <table class="tabular">
          <thead><tr><th>Friday 7</th><th>3 went two days this week</th><th>2</th></tr></thead>
          <tbody><tr><td>" 21</td><td>2 went 5 days this week</td><td>5</td></tr></tbody>
        </table>
      HTML
    end

    let(:declared) do
      <<~HTML
        <table class="tabular">
          <thead><tr><th class="bang">Date</th><th class="bang">Note</th></tr></thead>
          <tbody><tr><td>July 4</td><td>2 went 4 days</td></tr></tbody>
        </table>
      HTML
    end

    it 'demotes a header row the transcriber never declared' do
      result = doc(invented)

      expect(result.css('th')).to be_empty
      expect(result.css('thead')).to be_empty
      expect(result.css('tbody tr').first.css('td').map(&:text))
        .to eq(['Friday 7', '3 went two days this week', '2'])
    end

    it 'keeps the demoted row in its original position' do
      expect(doc(invented).css('tr').map { |row| row.css('td, th').first.text })
        .to eq(['Friday 7', '" 21'])
    end

    it 'marks a demoted table as a table so Chrome does not treat it as layout' do
      expect(doc(invented).at_css('table')['role']).to eq('table')
    end

    it 'describes a table whose headers were never transcribed' do
      description = doc(invented).at_css('img')

      expect(description['alt']).to eq(
        'Table as transcribed, 2 rows by 3 columns. Column headers were not ' \
        'marked in the original transcription, so cells are read without them.'
      )
      expect(description.next_element.name).to eq('table')
    end

    it 'keeps the description invisible' do
      description = doc(invented).at_css('img')

      expect(description['src']).to start_with('data:image/gif;base64,')
      expect(description['style']).to include('width:1px')
    end

    it 'keeps headers the transcriber did declare' do
      result = doc(declared)

      expect(result.css('thead th').map(&:text)).to eq(%w[Date Note])
      expect(result.at_css('table')['role']).to be_nil
    end

    it 'scopes declared column headers so cells inherit them' do
      expect(doc(declared).css('thead th').map { |th| th['scope'] }).to eq(%w[col col])
    end

    it 'does not describe a table that has real headers' do
      expect(doc(declared).at_css('img')).to be_nil
    end

    it 'scopes a lone leading header cell to its row' do
      html = '<table><tr><th>Oats</th><td>12</td><td>bushels</td></tr></table>'

      expect(doc(html).at_css('th')['scope']).to eq('row')
    end

    it 'leaves a hand-coded header row alone' do
      html = '<table><tr><th>A</th><th>B</th></tr><tr><td>1</td><td>2</td></tr></table>'

      result = doc(html)
      expect(result.css('th').map(&:text)).to eq(%w[A B])
      expect(result.at_css('img')).to be_nil
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
