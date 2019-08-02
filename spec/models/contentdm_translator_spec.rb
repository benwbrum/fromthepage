require 'spec_helper'
require 'contentdm_translator'

RSpec.describe ContentdmTranslator do
    describe '#cdm_url_to_iiif' do

        let(:item_url){ 'https://cdm123.contentdm.oclc.org/digital/collection/COL1D/id/123/' }
        let(:collection_url){ 'https://cdm123.contentdm.oclc.org/digital/collection/COL1D/' }
        let(:repository_url){ 'https://cdm123.contentdm.oclc.org/' }

        it "returns a message for a bad URL" do
            expect { ContentdmTranslator.cdm_url_to_iiif('BadUrl') }.to raise_error
        end
        it "returns an good iiif url for an item" do
            url = ContentdmTranslator.cdm_url_to_iiif(item_url)
            expect(url).to eq('https://cdm123.contentdm.oclc.org/iiif/info/COL1D/123/manifest.json')
        end
        it "returns an good iiif url for collection" do
            url = ContentdmTranslator.cdm_url_to_iiif(collection_url)
            expect(url).to eq('https://cdm123.contentdm.oclc.org/iiif/info/COL1D/manifest.json')
        end
        it "returns an good iiif url for repository" do
            url = ContentdmTranslator.cdm_url_to_iiif(repository_url)
            expect(url).to eq('https://cdm123.contentdm.oclc.org/iiif/info/manifest.json')
        end
    end
end