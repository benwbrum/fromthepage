require 'spec_helper'
require 'contentdm_translator'

RSpec.describe ContentdmTranslator do
  describe '#transcript_for_page' do
    let(:created_at) { Time.zone.parse('2026-05-01 12:00:00') }
    let(:ai_transcription) do
      instance_double(AiTranscription, source_text: 'AI draft text', model: 'gemini-2.5-pro', created_at: created_at)
    end

    it 'returns human transcription when transcript source is human only' do
      page = instance_double(Page, verbatim_transcription_plaintext: 'Human text', ai_transcription: ai_transcription)
      cdm_setting = instance_double(CdmExportSetting, transcript_source: CdmExportSetting::HUMAN_ONLY, prepend_ai_warning: false)

      transcript_text, ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)

      expect(transcript_text).to eq('Human text')
      expect(ai).to be_nil
    end

    it 'falls back to AI transcription when human text is blank and AI fallback is enabled' do
      page = instance_double(Page, verbatim_transcription_plaintext: '', ai_transcription: ai_transcription)
      cdm_setting = instance_double(CdmExportSetting, transcript_source: CdmExportSetting::HUMAN_AND_AI, prepend_ai_warning: false)

      transcript_text, ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)

      expect(transcript_text).to eq('AI draft text')
      expect(ai).to eq(ai_transcription)
    end

    it 'prepends a warning that includes model and run date when requested' do
      page = instance_double(Page, verbatim_transcription_plaintext: nil, ai_transcription: ai_transcription)
      cdm_setting = instance_double(CdmExportSetting, transcript_source: CdmExportSetting::HUMAN_AND_AI, prepend_ai_warning: true)

      transcript_text, ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)

      expect(transcript_text).to start_with('Warning: This transcript is AI-generated (gemini-2.5-pro 2026-05-01).')
      expect(transcript_text).to end_with("\nAI draft text")
      expect(ai).to eq(ai_transcription)
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
