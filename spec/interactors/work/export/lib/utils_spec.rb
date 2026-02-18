require 'spec_helper'

describe Work::Export::Lib::Utils do
  describe '.process_table' do
    let(:page) { double('page') }
    let(:preserve_lb) { false }
    let(:flatten_links) { false }

    # Helper method to calculate expected column width for paragraph columns
    def expected_column_width(column_count)
      (0.9 / column_count).round(2)
    end

    context 'with a small table (3 columns)' do
      let(:table_xml) do
        <<~XML
          <table>
            <thead>
              <tr><th>Col 1</th><th>Col 2</th><th>Col 3</th></tr>
            </thead>
            <tbody>
              <tr><td>Value 1</td><td>Value 2</td><td>Value 3</td></tr>
            </tbody>
          </table>
        XML
      end

      it 'uses paragraph columns without font scaling or landscape' do
        table_element = REXML::Document.new(table_xml).root
        result = described_class.process_table(page, table_element, preserve_lb, flatten_links)

        # Should use paragraph columns (p{width})
        expected_width = expected_column_width(3)
        expect(result).to include("p{#{expected_width}\\linewidth}")
        # Should NOT use landscape mode
        expect(result).not_to include('\\begin{landscape}')
        # Should NOT use small font
        expect(result).not_to include('\\small')
        expect(result).not_to include('\\footnotesize')
      end
    end

    context 'with a 5-column table' do
      let(:table_xml) do
        <<~XML
          <table>
            <thead>
              <tr><th>C1</th><th>C2</th><th>C3</th><th>C4</th><th>C5</th></tr>
            </thead>
            <tbody>
              <tr><td>V1</td><td>V2</td><td>V3</td><td>V4</td><td>V5</td></tr>
            </tbody>
          </table>
        XML
      end

      it 'uses paragraph columns with small font but no landscape' do
        table_element = REXML::Document.new(table_xml).root
        result = described_class.process_table(page, table_element, preserve_lb, flatten_links)

        # Should use paragraph columns with appropriate width
        expected_width = expected_column_width(5)
        expect(result).to include("p{#{expected_width}\\linewidth}")
        # Should use small font
        expect(result).to include('\\small')
        # Should NOT use landscape mode
        expect(result).not_to include('\\begin{landscape}')
        expect(result).not_to include('\\footnotesize')
      end
    end

    context 'with an 8-column table' do
      let(:table_xml) do
        <<~XML
          <table>
            <thead>
              <tr><th>C1</th><th>C2</th><th>C3</th><th>C4</th><th>C5</th><th>C6</th><th>C7</th><th>C8</th></tr>
            </thead>
            <tbody>
              <tr><td>V1</td><td>V2</td><td>V3</td><td>V4</td><td>V5</td><td>V6</td><td>V7</td><td>V8</td></tr>
            </tbody>
          </table>
        XML
      end

      it 'uses landscape mode with left-aligned columns and footnotesize font' do
        table_element = REXML::Document.new(table_xml).root
        result = described_class.process_table(page, table_element, preserve_lb, flatten_links)

        # Should use left-aligned columns for flexibility
        expect(result).to include('@{}l l l l l l l l@{}')
        # Should use landscape mode
        expect(result).to include('\\begin{landscape}')
        expect(result).to include('\\end{landscape}')
        # Should use footnotesize font
        expect(result).to include('\\footnotesize')
        # Should NOT use small font
        expect(result).not_to include('\\small')
      end
    end

    context 'with a 10-column table' do
      let(:table_xml) do
        <<~XML
          <table>
            <thead>
              <tr><th>C1</th><th>C2</th><th>C3</th><th>C4</th><th>C5</th><th>C6</th><th>C7</th><th>C8</th><th>C9</th><th>C10</th></tr>
            </thead>
            <tbody>
              <tr><td>V1</td><td>V2</td><td>V3</td><td>V4</td><td>V5</td><td>V6</td><td>V7</td><td>V8</td><td>V9</td><td>V10</td></tr>
            </tbody>
          </table>
        XML
      end

      it 'uses landscape mode with left-aligned columns and footnotesize font' do
        table_element = REXML::Document.new(table_xml).root
        result = described_class.process_table(page, table_element, preserve_lb, flatten_links)

        # Should use left-aligned columns for flexibility
        expect(result).to include('@{}l l l l l l l l l l@{}')
        # Should use landscape mode
        expect(result).to include('\\begin{landscape}')
        expect(result).to include('\\end{landscape}')
        # Should use footnotesize font
        expect(result).to include('\\footnotesize')
      end
    end
  end
end
