require 'spec_helper'
require 'contentdm_translator'

RSpec.describe ContentdmTranslator do
  describe '.transcript_for_page' do
    let(:created_at)      { Time.zone.parse('2026-05-01 12:00:00') }
    let(:ai_transcription) do
      instance_double(AiTranscription, source_text: 'AI draft text', model: 'gemini-2.5-pro', created_at: created_at)
    end

    context 'when cdm_setting is nil' do
      it 'returns the human transcript and no AI object' do
        page = instance_double(Page, verbatim_transcription_plaintext: 'human text')
        text, ai = ContentdmTranslator.transcript_for_page(page, nil)
        expect(text).to eq('human text')
        expect(ai).to be_nil
      end
    end

    context 'when transcript_source is human_only' do
      let(:cdm_setting) { instance_double(CdmExportSetting, transcript_source: CdmExportSetting::HUMAN_ONLY) }

      it 'returns the human transcript regardless of AI drafts' do
        page = instance_double(Page, verbatim_transcription_plaintext: 'human text')
        text, ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)
        expect(text).to eq('human text')
        expect(ai).to be_nil
      end
    end

    context 'when transcript_source is human_and_ai' do
      context 'when a human transcript exists' do
        it 'returns the human transcript and no AI object' do
          page = instance_double(Page, verbatim_transcription_plaintext: 'human text')
          cdm_setting = instance_double(CdmExportSetting, transcript_source: CdmExportSetting::HUMAN_AND_AI)
          text, ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)
          expect(text).to eq('human text')
          expect(ai).to be_nil
        end
      end

      context 'when no human transcript exists and an AI draft exists' do
        let(:page) { instance_double(Page, verbatim_transcription_plaintext: '', ai_transcription: ai_transcription) }

        it 'returns the AI draft text and the AI object' do
          cdm_setting = instance_double(CdmExportSetting, transcript_source: CdmExportSetting::HUMAN_AND_AI, prepend_ai_warning: false)
          text, ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)
          expect(text).to eq('AI draft text')
          expect(ai).to eq(ai_transcription)
        end

        it 'prepends a warning with model and date when prepend_ai_warning is true' do
          cdm_setting = instance_double(CdmExportSetting, transcript_source: CdmExportSetting::HUMAN_AND_AI, prepend_ai_warning: true)
          text, ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)
          expect(text).to start_with('Warning: This transcript is AI-generated (gemini-2.5-pro 2026-05-01).')
          expect(text).to end_with("\nAI draft text")
          expect(ai).to eq(ai_transcription)
        end

        it 'does not add a warning prefix when prepend_ai_warning is false' do
          cdm_setting = instance_double(CdmExportSetting, transcript_source: CdmExportSetting::HUMAN_AND_AI, prepend_ai_warning: false)
          text, _ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)
          expect(text).not_to include('Warning:')
        end
      end

      context 'when no human transcript exists and no AI draft exists' do
        it 'returns nil transcript and no AI object' do
          page = instance_double(Page, verbatim_transcription_plaintext: nil, ai_transcription: nil)
          cdm_setting = instance_double(CdmExportSetting, transcript_source: CdmExportSetting::HUMAN_AND_AI)
          text, ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)
          expect(text).to be_nil
          expect(ai).to be_nil
        end
      end
    end
  end


  describe '.export_work_to_cdm_with_retry' do
    let(:work)     { double('work') }
    let(:username) { 'user' }
    let(:password) { 'pass' }
    let(:license)  { 'lic' }

    before { allow(described_class).to receive(:export_work_to_cdm) }

    it 'calls export_work_to_cdm once when no error occurs' do
      described_class.export_work_to_cdm_with_retry(work, username, password, license)
      expect(described_class).to have_received(:export_work_to_cdm).once
    end

    it 'retries on Net::ReadTimeout and succeeds on second attempt' do
      call_count = 0
      allow(described_class).to receive(:export_work_to_cdm) do
        call_count += 1
        raise Net::ReadTimeout if call_count == 1
      end
      allow(described_class).to receive(:sleep)

      described_class.export_work_to_cdm_with_retry(work, username, password, license)
      expect(described_class).to have_received(:export_work_to_cdm).twice
    end

    it 'retries on Savon::HTTPError (502) and succeeds on second attempt' do
      call_count = 0
      http_response = double('http_response', code: 502, headers: {}, body: 'Bad gateway')
      allow(described_class).to receive(:export_work_to_cdm) do
        call_count += 1
        raise Savon::HTTPError.new(http_response) if call_count == 1
      end
      allow(described_class).to receive(:sleep)

      described_class.export_work_to_cdm_with_retry(work, username, password, license)
      expect(described_class).to have_received(:export_work_to_cdm).twice
    end

    it 'gives up after max delay is reached for Savon::HTTPError' do
      http_response = double('http_response', code: 502, headers: {}, body: 'Bad gateway')
      allow(described_class).to receive(:export_work_to_cdm).and_raise(Savon::HTTPError.new(http_response))
      allow(described_class).to receive(:sleep)

      expect { described_class.export_work_to_cdm_with_retry(work, username, password, license) }.not_to raise_error
    end
  end

  describe '#cdm_url_to_iiif' do
    let(:item_url) { 'https://digital.archives.alabama.gov/digital/collection/supreme_court/id/7076' }
    let(:collection_url) { 'https://digital.archives.alabama.gov/digital/collection/supreme_court' }
    let(:repository_url) { 'https://digital.archives.alabama.gov' }

    let(:vanity_item) { 'http://www.digitalindy.org/cdm/compoundobject/collection/ahs/id/200/rec/3' }
    let(:vanity_collection) { 'http://www.digitalindy.org/cdm/landingpage/collection/ahs' }
    let(:vanity_collection_2) { 'http://www.digitalindy.org/cdm/search/collection/ahs' }
    let(:vanity_repository) { 'http://www.digitalindy.org' }

    context 'when collection aliases contain punctuation' do
      before do
        allow(ContentdmTranslator).to receive(:get_cdm_host_from_url).and_return('kdl')
        allow(URI).to receive(:open).and_return(StringIO.new('{}'))
      end

      it 'translates a hyphenated item alias and permits trailing routes' do
        url = ContentdmTranslator.cdm_url_to_iiif('https://kdl.contentdm.oclc.org/digital/collection/tu-medtheses/id/4805/rec/1')

        expect(url).to eq('https://kdl.contentdm.oclc.org/iiif/info/tu-medtheses/4805/manifest.json')
      end

      it 'translates a hyphenated collection alias' do
        url = ContentdmTranslator.cdm_url_to_iiif('https://kdl.contentdm.oclc.org/digital/collection/tu-medtheses')

        expect(url).to eq('https://kdl.contentdm.oclc.org/iiif/info/tu-medtheses/manifest.json')
      end

      it 'does not treat a malformed item path as a collection URL' do
        expect do
          ContentdmTranslator.cdm_url_to_iiif('https://kdl.contentdm.oclc.org/digital/collection/tu-medtheses/id/not-a-record')
        end.to raise_error(ArgumentError, %r{/id/ but no valid numeric record ID})
      end
    end

    context 'when an item belongs to a compound object' do
      let(:item_api_url) do
        'https://kdl.contentdm.oclc.org/digital/api/singleitem/collection/tu-medtheses/id/4805'
      end

      before do
        allow(ContentdmTranslator).to receive(:get_cdm_host_from_url).and_return('kdl')
        allow(URI).to receive(:open).and_return(StringIO.new('{}'))
      end

      it 'uses the parent record manifest' do
        allow(URI).to receive(:open).with(item_api_url).and_return(StringIO.new('{"parentId":"5000"}'))

        url = ContentdmTranslator.cdm_url_to_iiif('https://kdl.contentdm.oclc.org/digital/collection/tu-medtheses/id/4805')

        expect(url).to eq('https://kdl.contentdm.oclc.org/iiif/info/tu-medtheses/5000/manifest.json')
      end

      it 'supports parent IDs nested in object information' do
        response = { objectInfo: { parentId: 5000 } }.to_json
        allow(URI).to receive(:open).with(item_api_url).and_return(StringIO.new(response))

        url = ContentdmTranslator.cdm_url_to_iiif('https://kdl.contentdm.oclc.org/digital/collection/tu-medtheses/id/4805')

        expect(url).to eq('https://kdl.contentdm.oclc.org/iiif/info/tu-medtheses/5000/manifest.json')
      end

      it 'uses the requested record when it has no parent' do
        allow(URI).to receive(:open).with(item_api_url).and_return(StringIO.new('{"parentId":-1}'))

        url = ContentdmTranslator.cdm_url_to_iiif('https://kdl.contentdm.oclc.org/digital/collection/tu-medtheses/id/4805')

        expect(url).to eq('https://kdl.contentdm.oclc.org/iiif/info/tu-medtheses/4805/manifest.json')
      end

      it 'rejects an invalid parent ID' do
        allow(URI).to receive(:open).with(item_api_url).and_return(StringIO.new('{"parentId":"not-an-id"}'))

        expect do
          ContentdmTranslator.cdm_url_to_iiif('https://kdl.contentdm.oclc.org/digital/collection/tu-medtheses/id/4805')
        end.to raise_error(ArgumentError, /invalid parent ID/)
      end

      it 'does not request item information for collection URLs' do
        ContentdmTranslator.cdm_url_to_iiif('https://kdl.contentdm.oclc.org/digital/collection/tu-medtheses')

        expect(URI).not_to have_received(:open).with(%r{/digital/api/singleitem/})
      end
    end

    context 'default' do
      around(:each) do |example|
        VCR.use_cassette('cdm/digital-alabama', record: :none) do
          example.run
        end
      end
      it "returns a message for a bad URL" do
        expect { ContentdmTranslator.cdm_url_to_iiif('BadUrl') }.to raise_error StandardError
      end
      it "returns an good iiif url for an item" do
        url = ContentdmTranslator.cdm_url_to_iiif(item_url)
        expect(url).to eq('https://cdm17217.contentdm.oclc.org/iiif/info/supreme_court/7076/manifest.json')
      end
      it "returns an good iiif url for collection" do
        url = ContentdmTranslator.cdm_url_to_iiif(collection_url)
        expect(url).to eq('https://cdm17217.contentdm.oclc.org/iiif/info/supreme_court/manifest.json')
      end
      it "returns an good iiif url for repository" do
        url = ContentdmTranslator.cdm_url_to_iiif(repository_url)
        expect(url).to eq('https://cdm17217.contentdm.oclc.org/iiif/info/manifest.json')
      end
    end
    context "for vanity URL" do
      around(:each) do |example|
        VCR.use_cassette('cdm/digitalindy.org', record: :none) do
          example.run
        end
      end

      it "item" do
        url = ContentdmTranslator.cdm_url_to_iiif(vanity_item)
        expect(url).to eq('https://cdm17308.contentdm.oclc.org/iiif/info/ahs/200/manifest.json')
      end
      it "collection" do
        url = ContentdmTranslator.cdm_url_to_iiif(vanity_collection)
        expect(url).to eq('https://cdm17308.contentdm.oclc.org/iiif/info/ahs/manifest.json')
      end
      it "collection variant" do
        url = ContentdmTranslator.cdm_url_to_iiif(vanity_collection_2)
        expect(url).to eq('https://cdm17308.contentdm.oclc.org/iiif/info/ahs/manifest.json')
      end
      it "repository" do
        url = ContentdmTranslator.cdm_url_to_iiif(vanity_repository)
        expect(url).to eq('https://cdm17308.contentdm.oclc.org/iiif/info/manifest.json')
      end
    end
  end
end
