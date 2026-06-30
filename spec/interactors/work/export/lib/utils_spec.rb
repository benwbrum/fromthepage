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

    context 'with a table whose thead contains th elements wrapped in a tr' do
      let(:xml) do
        <<~XML
          <page><table class="tabular"><thead><tr>
            <th>Street No.</th><th>Name</th><th>Sex</th><th>Age</th>
          </tr></thead><tbody>
            <tr><td>Beach</td><td>54</td><td>Smith John</td><td>male</td></tr>
          </tbody></table></page>
        XML
      end

      it 'generates a valid xltabular environment' do
        result = described_class.xml_to_latex(page: page, xml_text: xml)
        expect(result).to include('\\begin{xltabular}')
        expect(result).to include('\\end{xltabular}')
      end

      it 'includes toprule, midrule, and bottomrule' do
        result = described_class.xml_to_latex(page: page, xml_text: xml)
        expect(result).to include('\\toprule')
        expect(result).to include('\\midrule')
        expect(result).to include('\\bottomrule')
      end

      it 'separates header columns with & and terminates the row with \\\\' do
        result = described_class.xml_to_latex(page: page, xml_text: xml)
        expect(result).to match(/Street No\. & Name & Sex & Age \\\\\s*\n/)
      end

      it 'places \\midrule after the header row terminator' do
        result = described_class.xml_to_latex(page: page, xml_text: xml)
        expect(result).to match(/\\\\\s*\n\\midrule/)
      end

      it 'places header content between \\toprule and \\midrule' do
        result = described_class.xml_to_latex(page: page, xml_text: xml)
        toprule_pos = result.index('\\toprule')
        header_pos  = result.index('Street No.')
        midrule_pos = result.index('\\midrule')
        expect(header_pos).to be > toprule_pos
        expect(header_pos).to be < midrule_pos
      end
    end

    context 'with a table whose thead contains th elements directly (no tr wrapper)' do
      let(:xml) do
        <<~XML
          <page><table class="tabular"><thead>
            <th>Street No.</th><th>Name</th><th>Sex</th><th>Age</th>
          </thead><tbody>
            <tr><td>Beach</td><td>54</td><td>Smith John</td><td>male</td></tr>
          </tbody></table></page>
        XML
      end

      it 'generates a valid xltabular environment' do
        result = described_class.xml_to_latex(page: page, xml_text: xml)
        expect(result).to include('\\begin{xltabular}')
        expect(result).to include('\\end{xltabular}')
      end

      it 'separates header columns with & and terminates the row with \\\\' do
        result = described_class.xml_to_latex(page: page, xml_text: xml)
        expect(result).to match(/Street No\. & Name & Sex & Age \\\\\s*\n/)
      end

      it 'places \\midrule after the header row terminator, not before it' do
        result = described_class.xml_to_latex(page: page, xml_text: xml)
        expect(result).to match(/\\\\\s*\n\\midrule/)
        expect(result).not_to match(/Street No\..*\\\midrule/)
      end

      it 'does not concatenate header cells without separators' do
        result = described_class.xml_to_latex(page: page, xml_text: xml)
        expect(result).not_to include('Street No.NameSexAge')
      end

      it 'preserves cell content and ordering after normalization' do
        result = described_class.xml_to_latex(page: page, xml_text: xml)
        # Header cells must appear in original order with correct separators
        expect(result).to match(/Street No\. & Name & Sex & Age/)
        # Body cell content must also be intact
        expect(result).to match(/Beach & 54 & Smith John & male/)
      end
    end
  end
end
