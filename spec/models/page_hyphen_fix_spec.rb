require 'spec_helper'

describe Page do
  describe 'hyphen handling in plaintext export' do
    let(:page) { build_stubbed(:page) }
    
    it 'should remove hyphens for soft line breaks in formatted_plaintext_doc' do
      # Create XML with soft line breaks (break="no")
      xml_content = '<?xml version="1.0" encoding="UTF-8"?><page><p>correct pron<lb break="no"/>ounciation [sic].</p><p>I am Dear Sir<lb/>Yours Faith<lb break="no"/>fully<lb/>Samuel Gason</p></page>'
      
      doc = Nokogiri::XML(xml_content)
      result = page.send(:formatted_plaintext_doc, doc)
      
      # The result should join hyphenated words without hyphens or spaces
      expect(result).to include("pronounciation")
      expect(result).to include("Faithfully")
      expect(result).not_to include("pron-\nounciation")
      expect(result).not_to include("Faith-\nfully")
    end
    
    it 'should preserve hard line breaks' do
      xml_content = '<?xml version="1.0" encoding="UTF-8"?><page><p>line one<lb/>line two</p></page>'
      
      doc = Nokogiri::XML(xml_content)
      result = page.send(:formatted_plaintext_doc, doc)
      
      # Hard breaks should become newlines
      expect(result).to include("line one\nline two")
    end
    
    it 'should handle mixed soft and hard breaks correctly' do
      xml_content = '<?xml version="1.0" encoding="UTF-8"?><page><p>first line<lb/>second line with hyphen<lb break="no"/>ation</p></page>'
      
      doc = Nokogiri::XML(xml_content)
      result = page.send(:formatted_plaintext_doc, doc)
      
      expect(result).to include("first line\nsecond line with hyphenation")
      expect(result).not_to include("hyphen-\nation")
    end
    
    it 'should handle custom hyphen text in soft breaks' do
      xml_content = '<?xml version="1.0" encoding="UTF-8"?><page><p>Faith<lb break="no">:</lb>fully</p></page>'
      
      doc = Nokogiri::XML(xml_content)
      result = page.send(:formatted_plaintext_doc, doc)
      
      # Should join without the custom hyphen character
      expect(result).to include("Faithfully")
      expect(result).not_to include("Faith:\nfully")
    end
  end
  
  describe 'plaintext export methods' do
    let(:collection) { create(:collection) }
    let(:work) { create(:work, collection: collection) }
    let(:page) { create(:page, work: work) }
    
    before do
      # Set up page with hyphenated content
      page.source_text = "correct pron-\nounciation [sic].\n\nI am Dear Sir\nYours Faith-\nfully\nSamuel Gason"
      page.save!
    end
    
    it 'should export hyphenated words correctly in verbatim plaintext' do
      result = page.verbatim_transcription_plaintext
      
      # Should join hyphenated words
      expect(result).to include("pronounciation")
      expect(result).to include("Faithfully")
      expect(result).not_to include("pron-")
      expect(result).not_to include("Faith-")
    end
    
    it 'should export hyphenated words correctly in emended plaintext' do
      result = page.emended_transcription_plaintext
      
      # Should join hyphenated words
      expect(result).to include("pronounciation")
      expect(result).to include("Faithfully")
      expect(result).not_to include("pron-")
      expect(result).not_to include("Faith-")
    end
  end
end