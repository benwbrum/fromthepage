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

  describe '.xml_to_latex table rendering' do
    let(:page) { nil }

    it 'terminates each table row with \\\\{} to prevent [ from being parsed as optional spacing' do
      xml = <<~XML
        <page><table><tbody>
          <tr><td>Jan 1</td><td>amount</td></tr>
          <tr><td>[illegible]</td><td>30</td></tr>
        </tbody></table></page>
      XML

      result = described_class.xml_to_latex(page: page, xml_text: xml)

      # Each row must end with \\{} so that a following [ is not parsed as
      # the optional vertical-spacing argument to \\, which would cause
      # "Missing number, treated as zero" in lualatex.
      row_terminators = result.scan(/\\\\(\{\})?/).map { |m| m[0] }
      expect(row_terminators).to all(eq('{}'))
    end

    it 'includes xltabular environment with correct column count' do
      xml = <<~XML
        <page><table><tbody>
          <tr><td>A</td><td>B</td><td>C</td></tr>
        </tbody></table></page>
      XML

      result = described_class.xml_to_latex(page: page, xml_text: xml)

      expect(result).to include('\\begin{xltabular}{\\textwidth}{XXX}')
      expect(result).to include('\\end{xltabular}')
    end

    it 'renders cell content with & column separators' do
      xml = <<~XML
        <page><table><tbody>
          <tr><td>foo</td><td>bar</td></tr>
        </tbody></table></page>
      XML

      result = described_class.xml_to_latex(page: page, xml_text: xml)

      expect(result).to include('foo & bar')
    end

    it 'uses \\toprule and \\midrule for thead rows' do
      xml = <<~XML
        <page><table>
          <thead><tr><th>Header</th><th>Col2</th></tr></thead>
          <tbody><tr><td>Data</td><td>Value</td></tr></tbody>
        </table></page>
      XML

      result = described_class.xml_to_latex(page: page, xml_text: xml)

      expect(result).to include('\\toprule')
      expect(result).to include('\\midrule')
      expect(result).to include('\\bottomrule')
    end
  end
end
