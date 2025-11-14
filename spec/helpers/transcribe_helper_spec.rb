require 'spec_helper'

RSpec.describe TranscribeHelper, type: :helper do
  describe '#excerpt_subject' do
    let(:page) { FactoryBot.build_stubbed(:page,
      source_text: "5\n4\n3\n2\n1\n[[Transcription]]\n1\n2\n3\n4\n5",
      source_translation: "5\n4\n3\n2\n1\n[[Translation]]\n1\n2\n3\n4\n5",
    ) }
    it 'should default to transcription match with three lines of context' do
      expected = "3\n2\n1\n<b>[[Transcription]]</b>\n1\n2\n3"
      expect(helper.excerpt_subject(page, 'Transcription')).to eq(expected)
    end

    it 'should match translation based on option' do
      expected = "3\n2\n1\n<b>[[Translation]]</b>\n1\n2\n3"
      expect(helper.excerpt_subject(page, 'Translation', { text_type: 'translation' }))
        .to eq(expected)
    end

    it 'should match the title and one line on either side' do
      expected = "1\n<b>[[Transcription]]</b>\n1"
      expect(helper.excerpt_subject(page, 'Transcription', { radius: 1 }))
        .to eq(expected)
    end

    it 'should match only the title with radius 0' do
      expected = "<b>[[Transcription]]</b>"
      expect(helper.excerpt_subject(page, 'Transcription', { radius: 0 }))
        .to eq(expected)
    end
    it 'should return only title with invalid parameter' do
      expected = "<b>[[Transcription]]</b>"
      expect(helper.excerpt_subject(page, 'Transcription', { radius: -1 }))
        .to eq(expected)
    end
    it "should return only title if there's no match" do
      expected = "<b>BADMATCH</b>"
      expect(helper.excerpt_subject(page, 'BADMATCH'))
        .to eq(expected)
    end
  end

  describe '#osd_source' do
    let(:work) { FactoryBot.build_stubbed(:work) }

    context 'when page has base_image with special characters' do
      let(:page) { FactoryBot.build_stubbed(:page, base_image: '/public/images/uploaded/32237431/ASS 642 #11 f. 1r.jpeg') }

      before do
        allow(page).to receive(:sc_canvas).and_return(nil)
        allow(page).to receive(:ia_leaf).and_return(nil)
        allow(page).to receive(:canonical_facsimile_url).and_return('/public/images/uploaded/32237431/ASS 642 #11 f. 1r.jpeg')
        allow(helper).to receive(:browser).and_return(double(platform: double(ios?: false), webkit?: false))
      end

      it 'returns URL encoded image source' do
        result = helper.osd_source(page, work)
        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
        
        parsed = JSON.parse(result[0])
        expect(parsed['type']).to eq('image')
        expect(parsed['url']).to eq('/images/uploaded/32237431/ASS%20642%20%2311%20f.%201r.jpeg')
      end
    end
  end
end
