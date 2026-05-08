require 'spec_helper'
require 'contentdm_translator'

RSpec.describe ContentdmTranslator do
  describe '.transcript_for_page' do
    let(:page)        { create(:page) }
    let(:cdm_setting) { build(:cdm_export_setting) }

    context 'when cdm_setting is nil' do
      it 'returns the human transcript and no AI object' do
        allow(page).to receive(:verbatim_transcription_plaintext).and_return('human text')
        text, ai = ContentdmTranslator.transcript_for_page(page, nil)
        expect(text).to eq('human text')
        expect(ai).to be_nil
      end
    end

    context 'when transcript_source is human_only' do
      it 'returns the human transcript regardless of AI drafts' do
        allow(page).to receive(:verbatim_transcription_plaintext).and_return('human text')
        text, ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)
        expect(text).to eq('human text')
        expect(ai).to be_nil
      end
    end

    context 'when transcript_source is human_and_ai' do
      before { cdm_setting.transcript_source = CdmExportSetting::HUMAN_AND_AI }

      context 'when a human transcript exists' do
        it 'returns the human transcript and no AI object' do
          allow(page).to receive(:verbatim_transcription_plaintext).and_return('human text')
          text, ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)
          expect(text).to eq('human text')
          expect(ai).to be_nil
        end
      end

      context 'when no human transcript exists' do
        before { allow(page).to receive(:verbatim_transcription_plaintext).and_return(nil) }

        context 'and an AI draft exists' do
          let(:ai_transcription) { create(:ai_transcription, page: page, source_text: 'AI draft text', status: :finished) }
          before { allow(page).to receive(:ai_transcription).and_return(ai_transcription) }

          it 'returns the AI draft text and the AI object' do
            text, ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)
            expect(text).to eq('AI draft text')
            expect(ai).to eq(ai_transcription)
          end

          context 'and prepend_ai_warning is true' do
            before { cdm_setting.prepend_ai_warning = true }

            it 'prepends the warning line to the AI text' do
              text, _ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)
              expect(text).to eq("Warning: This transcript is AI-generated.\nAI draft text")
            end
          end

          context 'and prepend_ai_warning is false' do
            it 'does not add a warning prefix' do
              text, _ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)
              expect(text).not_to include('Warning:')
            end
          end
        end

        context 'and no AI draft exists' do
          before { allow(page).to receive(:ai_transcription).and_return(nil) }

          it 'returns nil transcript and no AI object' do
            text, ai = ContentdmTranslator.transcript_for_page(page, cdm_setting)
            expect(text).to be_nil
            expect(ai).to be_nil
          end
        end
      end
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
