require 'rails_helper'

RSpec.describe Page, type: :model do
  describe 'hyphen handling in plaintext exports' do
    let(:xml_with_soft_break) { '<p>correct pron<lb break="no"/>ounciation [sic].</p>' }
    let(:xml_with_custom_sigil) { '<p>some wor<lb break="no">~</lb>ds here.</p>' }
    
    let(:page) { create(:page) }

    describe '#verbatim_transcription_plaintext' do
      it 'preserves line continuation hyphens for verbatim exports' do
        page.update(xml_text: xml_with_soft_break)
        
        result = page.verbatim_transcription_plaintext
        
        # Verbatim should preserve the hyphen and line break
        expect(result).to include("pron-\nounciation")
      end

      it 'preserves custom sigils in verbatim exports' do
        page.update(xml_text: xml_with_custom_sigil)
        
        result = page.verbatim_transcription_plaintext
        
        # Should preserve the custom sigil (~)
        expect(result).to include("wor~\nds")
      end
    end

    describe '#emended_transcription_plaintext' do
      it 'joins hyphenated words for emended exports' do
        page.update(xml_text: xml_with_soft_break)
        
        result = page.emended_transcription_plaintext
        
        # Emended should join the words without hyphen
        expect(result).to include("pronounciation")
        expect(result).not_to include("pron-")
      end

      it 'joins words with custom sigils in emended exports' do
        page.update(xml_text: xml_with_custom_sigil)
        
        result = page.emended_transcription_plaintext
        
        # Should join words without the custom sigil
        expect(result).to include("words")
        expect(result).not_to include("wor~")
      end
    end
    
    describe 'export endpoints behavior' do
      it 'maintains different behavior for different export types' do
        page.update(xml_text: xml_with_soft_break)
        
        verbatim = page.verbatim_transcription_plaintext
        emended = page.emended_transcription_plaintext
        
        # They should produce different results
        expect(verbatim).not_to eq(emended)
        
        # Verbatim preserves structure
        expect(verbatim).to include("-\n")
        
        # Emended modernizes text
        expect(emended).not_to include("-\n")
        expect(emended).to include("pronounciation")
      end
    end
  end
end