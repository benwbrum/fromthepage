require 'spec_helper'

describe ExportHelper do
  include ExportHelper

  describe '#xml_to_export_tei with head tags' do
    let(:context) { double('context', translation_mode: false) }

    context 'when entryHeading elements are present' do
      let(:xml_text) do
        <<~XML
          <?xml version='1.0' encoding='UTF-8'?>
          <page>
            <p>Some text before the heading.</p>
            <p><entryHeading title="Sept 28 Wednesday" depth="2">wiki heading mark-up</entryHeading></p>
            <p>Some text after the heading.</p>
          </page>
        XML
      end

      it 'should not place head elements inside p elements' do
        result = xml_to_export_tei(xml_text, context, 'TEST123')
        
        # Should not have head elements inside p elements
        expect(result).not_to match(/<p[^>]*>.*<head[^>]*>.*<\/head>.*<\/p>/m)
        
        # Should have head elements outside of p elements
        expect(result).to match(/<head[^>]*>.*<\/head>/m)
      end

      it 'should maintain proper div structure around head elements' do
        result = xml_to_export_tei(xml_text, context, 'TEST123')
        
        # Head elements should be properly structured with divs
        # This is the expected TEI structure where head elements are not nested in paragraphs
        expect(result).to match(/<\/p>.*<head[^>]*>.*<\/head>.*<p[^>]*>/m)
      end

      it 'should preserve head element attributes and content' do
        result = xml_to_export_tei(xml_text, context, 'TEST123')
        
        expect(result).to include('depth="2"')
        expect(result).to include('Sept 28 Wednesday')
      end
    end

    context 'when multiple entryHeading elements are present' do
      let(:xml_text) do
        <<~XML
          <?xml version='1.0' encoding='UTF-8'?>
          <page>
            <p>First paragraph.</p>
            <p><entryHeading title="First Heading" depth="1">heading1</entryHeading></p>
            <p>Content under first heading.</p>
            <p><entryHeading title="Second Heading" depth="2">heading2</entryHeading></p>
            <p>Content under second heading.</p>
          </page>
        XML
      end

      it 'should handle multiple head elements correctly' do
        result = xml_to_export_tei(xml_text, context, 'TEST123')
        
        # Should not have any head elements inside p elements
        expect(result).not_to match(/<p[^>]*>.*<head[^>]*>.*<\/head>.*<\/p>/m)
        
        # Should have both head elements
        expect(result).to include('First Heading')
        expect(result).to include('Second Heading')
        expect(result).to include('depth="1"')
        expect(result).to include('depth="2"')
      end
    end
  end
end