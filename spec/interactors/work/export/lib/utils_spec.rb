require 'spec_helper'

describe Work::Export::Lib::Utils do
  describe '.latex_escape' do
    it 'escapes standard LaTeX special characters' do
      expect(described_class.latex_escape('100% & more')).to eq('100\\% \\& more')
    end

    it 'strips U+2060 WORD JOINER characters' do
      text_with_wj = "NO COPYRIGHT\u{2060} - UNITED STATES"
      expect(described_class.latex_escape(text_with_wj)).to eq('NO COPYRIGHT - UNITED STATES')
    end

    it 'strips U+200B ZERO WIDTH SPACE characters' do
      text_with_zwsp = "hello\u{200B}world"
      expect(described_class.latex_escape(text_with_zwsp)).to eq('helloworld')
    end

    it 'strips U+200C ZERO WIDTH NON-JOINER characters' do
      text_with_zwnj = "hello\u{200C}world"
      expect(described_class.latex_escape(text_with_zwnj)).to eq('helloworld')
    end

    it 'strips U+200D ZERO WIDTH JOINER characters' do
      text_with_zwj = "hello\u{200D}world"
      expect(described_class.latex_escape(text_with_zwj)).to eq('helloworld')
    end

    it 'strips U+FEFF ZERO WIDTH NO-BREAK SPACE (BOM) characters' do
      text_with_bom = "\u{FEFF}hello world"
      expect(described_class.latex_escape(text_with_bom)).to eq('hello world')
    end

    it 'strips multiple invisible characters while preserving other content' do
      rights_statement = "NO COPYRIGHT\u{2060} - UNITED STATES"
      expect(described_class.latex_escape(rights_statement)).to eq('NO COPYRIGHT - UNITED STATES')
    end

    it 'returns empty string for blank input' do
      expect(described_class.latex_escape('')).to eq('')
      expect(described_class.latex_escape(nil)).to eq('')
    end
  end

  describe '.xml_to_latex' do
    let(:page) { nil }

    it 'renders table headers in a tr when thead contains direct th children' do
      xml = <<~XML
        <page><table class="tabular"><thead>
          <th>Street No.</th><th>Name</th><th>Sex</th><th>Age</th>
        </thead><tbody>
          <tr><td>458</td><td>John Smith</td><td>Male</td><td>54</td></tr>
        </tbody></table></page>
      XML

      result = described_class.xml_to_latex(page: page, xml_text: xml)

      expect(result).to include('\\begin{xltabular}{\\textwidth}{XXXX}')
      expect(result).to match(/Street No\. & Name & Sex & Age \\\\\s*\n\\midrule/)
    end

    it 'keeps malformed direct th headers separate from existing header rows' do
      xml = <<~XML
        <page><table class="tabular"><thead>
          <th>A</th><th>B</th>
          <tr><th>C</th><th>D</th></tr>
        </thead><tbody>
          <tr><td>1</td><td>2</td></tr>
        </tbody></table></page>
      XML

      result = described_class.xml_to_latex(page: page, xml_text: xml)

      expect(result).to match(/A & B \\\\\s*\nC & D \\\\\s*\n\\midrule/)
    end

    it 'returns empty string for a table with no rows' do
      xml = <<~XML
        <page><table class="tabular"></table></page>
      XML

      result = described_class.xml_to_latex(page: page, xml_text: xml)

      expect(result).not_to include('xltabular')
    end

    it 'returns empty string for a table with empty thead and tbody elements' do
      xml = <<~XML
        <page><table class="tabular"><thead></thead><tbody></tbody></table></page>
      XML

      result = described_class.xml_to_latex(page: page, xml_text: xml)

      expect(result).not_to include('xltabular')
    end
  end
end
