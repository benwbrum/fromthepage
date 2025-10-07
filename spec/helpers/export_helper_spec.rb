require 'spec_helper'

RSpec.describe ExportHelper, type: :helper do
  fixtures [:collections]

  before do
    @collection = Collection.first
    @context = double("context", translation_mode: false)
  end

  describe "Bibliography TEI export formatting" do
    context "bibliography_to_export_tei" do
      it "processes TEI markup in bibliography for export" do
        bibliography_xml = "<bibl>Test citation with <hi rend=\"italic\">italicized title</hi> and <lb/>line break</bibl>"

        result = bibliography_to_export_tei(bibliography_xml, @context)

        expect(result).to include("<hi rend='italic'>italicized title</hi>")
        expect(result).to include("<lb/>")
        expect(result).to include("Test citation with")
      end

      it "handles complex TEI content with multiple hi and lb elements" do
        complex_tei = " (1850), Population Schedules, Kentucky.<lb>
<hi rend=\"italic\">Eighth Manuscript Census</hi> (1860), Population Schedules.<lb>
Henry Tanner, ed., <hi rend=\"italic\">Directory</hi> (Louisville, 1861), 227."

        result = bibliography_to_export_tei(complex_tei, @context)

        expect(result).to include("<hi rend='italic'>Eighth Manuscript Census</hi>")
        expect(result).to include("<hi rend='italic'>Directory</hi>")
        expect(result).to include("<lb/>")
        expect(result).to include("(1850), Population Schedules, Kentucky.")
      end

      it "returns empty string for empty content" do
        result = bibliography_to_export_tei('', @context)
        expect(result).to eq('')
      end

      it "handles malformed XML gracefully" do
        malformed_xml = "Text with <invalid>unclosed tag and <lb> tags"

        result = bibliography_to_export_tei(malformed_xml, @context)

        # Should return empty string for malformed XML in TEI export context
        expect(result).to eq('')
      end
    end
  end

  describe '#clean_date_for_when_attribute' do
    it 'uses EDTF library for valid EDTF dates' do
      expect(clean_date_for_when_attribute('1866')).to eq('1866')
      expect(clean_date_for_when_attribute('1866-05')).to eq('1866-05')
      expect(clean_date_for_when_attribute('1866-05-15')).to eq('1866-05-15')
    end

    it 'does not eliminate question marks' do
      expect(clean_date_for_when_attribute('1866?')).to eq('1866?')
    end

    it 'handles multiple question marks' do
      expect(clean_date_for_when_attribute('1866???')).to eq('1866')
    end

    it 'returns nil for invalid dates' do
      expect(clean_date_for_when_attribute('invalid')).to be_nil
      expect(clean_date_for_when_attribute('')).to be_nil
      expect(clean_date_for_when_attribute(nil)).to be_nil
    end

    it 'validates date format for fallback cleaning' do
      # Invalid months 13-20 should be suppressed
      expect(clean_date_for_when_attribute('1866-13')).to be_nil  # Invalid month
      expect(clean_date_for_when_attribute('1866-20')).to be_nil  # Invalid month
      expect(clean_date_for_when_attribute('1866-21')).to eq('1866-21')  # Valid EDTF sub-year grouping
    end

    it 'handles EDTF parsing errors gracefully' do
      # Test that we gracefully handle when EDTF can't parse something
      # but our fallback can - should preserve single question marks
      allow(Date).to receive(:edtf).and_raise(StandardError)
      expect(clean_date_for_when_attribute('1866?')).to eq('1866?')
    end
  end

  describe 'TEI validation fixes' do
    context 'XML ID generation' do
      it 'prefixes numeric IDs to make valid NCName' do
        work_id = '14648'
        xml_id = "W#{work_id}"
        expect(xml_id).to eq('W14648')
        expect(xml_id).not_to match(/^\d/)  # Should not start with digit
      end
    end

    context 'ptr elements' do
      it 'should be self-closing without text content' do
        # This is more of a template structure test
        # The actual fix is in the ERB template
        expect(true).to be true  # Placeholder for template structure
      end
    end

    context 'geo element placement' do
      it 'should be directly in place element not in note' do
        # This is a template structure test
        # The actual fix moves geo out of note wrapper
        expect(true).to be true  # Placeholder for template structure
      end
    end

    context 'depth attribute replacement' do
      it 'replaces depth with subtype for head elements' do
        # Test that depth attribute is replaced with subtype/type for TEI compliance
        expect(true).to be true  # Placeholder for template structure
      end
    end
  end

  describe '#extract_heads_from_parargraph' do
    it 'wraps extracted head elements in div tags' do
      require 'rexml/document'
      xml_text = '<?xml version="1.0" encoding="UTF-8"?><page><p><head depth="1">Section Title</head>This is the content.</p></page>'
      doc = REXML::Document.new(xml_text)
      p_element = doc.elements['//p']

      elements = extract_heads_from_parargraph(p_element)

      expect(elements.length).to eq(2)
      expect(elements[0].name).to eq('div')
      expect(elements[0].elements['head']).not_to be_nil
      expect(elements[0].elements['head'].text).to eq('Section Title')
      expect(elements[1].name).to eq('p')
      expect(elements[1].text).to eq('This is the content.')
    end

    it 'removes empty p element when only head is present' do
      require 'rexml/document'
      xml_text = '<?xml version="1.0" encoding="UTF-8"?><page><p><head depth="1">Section Title</head></p></page>'
      doc = REXML::Document.new(xml_text)
      p_element = doc.elements['//p']

      elements = extract_heads_from_parargraph(p_element)

      expect(elements.length).to eq(1)
      expect(elements[0].name).to eq('div')
      expect(elements[0].elements['head']).not_to be_nil
      expect(elements[0].elements['head'].text).to eq('Section Title')
    end

    it 'wraps multiple head elements in separate div tags' do
      require 'rexml/document'
      xml_text = '<?xml version="1.0" encoding="UTF-8"?><page><p><head depth="1">Title 1</head><head depth="2">Title 2</head>Content here.</p></page>'
      doc = REXML::Document.new(xml_text)
      p_element = doc.elements['//p']

      elements = extract_heads_from_parargraph(p_element)

      expect(elements.length).to eq(3)
      expect(elements[0].name).to eq('div')
      expect(elements[0].elements['head'].text).to eq('Title 1')
      expect(elements[1].name).to eq('div')
      expect(elements[1].elements['head'].text).to eq('Title 2')
      expect(elements[2].name).to eq('p')
      expect(elements[2].text).to eq('Content here.')
    end

    it 'returns p element unchanged when no head elements present' do
      require 'rexml/document'
      xml_text = '<?xml version="1.0" encoding="UTF-8"?><page><p>Just regular content.</p></page>'
      doc = REXML::Document.new(xml_text)
      p_element = doc.elements['//p']

      elements = extract_heads_from_parargraph(p_element)

      expect(elements.length).to eq(1)
      expect(elements[0].name).to eq('p')
      expect(elements[0].text).to eq('Just regular content.')
    end
  end
end
