require 'spec_helper'

describe BibliographyXml do
  it 'preserves prose curly quotes and apostrophes while fixing attribute delimiters' do
    input = "<hi rend=‘italic’>Rennick’s “Place Names”</hi>"
    expect(described_class.normalize(input)).to eq("<hi rend='italic'>Rennick’s “Place Names”</hi>")
  end

  it 'preserves curly quotes within straight-quoted attributes and ampersands in CDATA' do
    input = %q(<hi title="Example rend=“italic”"><![CDATA[Cities & towns]]></hi>)
    expect(described_class.normalize(input)).to eq(input)
  end

  it 'preserves existing XML entities and numeric character references' do
    input = 'Cities &amp; towns &#38; villages &#x26; settlements'
    expect(described_class.normalize(input)).to eq(input)
  end

  it 'handles multiple bibliography elements and attributed line breaks without damaging valid XML' do
    input = '<bibl>One<lb n="1"/></bibl>\n<bibl>Two<br></bibl>'
    xml = described_class.parse(input)
    doc = Nokogiri::XML(xml) { |config| config.strict }
    expect(doc.xpath('//bibl').size).to eq(2)
    expect(doc.at_xpath('//lb')['n']).to eq('1')
  end
end
