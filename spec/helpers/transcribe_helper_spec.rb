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
      expect(helper.excerpt_subject(page, 'Translation', {:text_type => 'translation'}))
        .to eq(expected)
    end

    it 'should match the title and one line on either side' do
      expected = "1\n<b>[[Transcription]]</b>\n1"
      expect(helper.excerpt_subject(page, 'Transcription', {:radius => 1}))
        .to eq(expected)
    end

    it 'should match only the title with radius 0' do
      expected = "<b>[[Transcription]]</b>"
      expect(helper.excerpt_subject(page, 'Transcription', {:radius => 0}))
        .to eq(expected)
    end
    it 'should return only title with invalid parameter' do
      expected = "<b>[[Transcription]]</b>"
      expect(helper.excerpt_subject(page, 'Transcription', {:radius => -1}))
        .to eq(expected)
    end
    it "should return only title if there's no match" do
      expected = "<b>BADMATCH</b>"
      expect(helper.excerpt_subject(page, 'BADMATCH'))
        .to eq(expected)
    end
  end
end