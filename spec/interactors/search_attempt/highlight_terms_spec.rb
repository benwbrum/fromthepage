require 'spec_helper'

RSpec.describe SearchAttempt::Lib::Utils do
  def highlight(text, query)
    Nokogiri::HTML.fragment(described_class.highlight_terms(text, query))
  end

  ['1)', "1')", '[x]', 'a\\b', 'a+b', 'a.b', '(a|b)', '<script>'].each do |term|
    it "highlights #{term.inspect} as literal text" do
      doc = highlight(ERB::Util.html_escape("before #{term} after"), term)
      expect(doc.css('span.highlighted').map(&:text)).to eq([term])
      expect(doc.text).to eq("before #{term} after")
      expect(doc.css('script')).to be_empty
    end
  end

  it 'does not turn encoded markup in a text node into HTML' do
    doc = highlight('&lt;img src=x onerror=alert(1)&gt; &amp; cat', 'cat')
    expect(doc.css('img')).to be_empty
    expect(doc.text).to eq('<img src=x onerror=alert(1)> & cat')
    expect(doc.css('.highlighted').text).to eq('cat')
  end

  it 'preserves tags, skips script/style text, and matches whole words case insensitively' do
    doc = highlight('<b>Cat</b> scatter dog<script>cat</script><style>cat</style>', 'cat dog')
    expect(doc.css('.highlighted').map(&:text)).to eq(['Cat', 'dog'])
    expect(doc.at_css('b').text).to eq('Cat')
    expect(doc.at_css('script').text).to eq('cat')
  end

  it 'handles empty or missing terms without adding empty highlights' do
    [nil, '', '   '].each do |query|
      expect(highlight('hello', query).css('.highlighted')).to be_empty
    end
  end
end
