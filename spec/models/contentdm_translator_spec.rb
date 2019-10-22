require 'spec_helper'
require 'contentdm_translator'

RSpec.describe ContentdmTranslator do
    describe '#cdm_url_to_iiif' do

        let(:item_url){ 'https://cdm123.contentdm.oclc.org/digital/collection/COL1D/id/123/' }
        let(:collection_url){ 'https://cdm123.contentdm.oclc.org/digital/collection/COL1D/' }
        let(:repository_url){ 'https://cdm123.contentdm.oclc.org/' }
        
        let(:vanity_item){ 'http://www.digitalindy.org/cdm/compoundobject/collection/ahs/id/200/rec/3' }
        let(:vanity_collection){ 'http://www.digitalindy.org/cdm/landingpage/collection/ahs' }
        let(:vanity_collection_2){ 'http://www.digitalindy.org/cdm/search/collection/ahs' }
        let(:vanity_repository){ 'http://www.digitalindy.org' }

        it "returns a message for a bad URL" do
            expect { ContentdmTranslator.cdm_url_to_iiif('BadUrl') }.to raise_error StandardError
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
        context "for vanity URL" do
            around(:each) do |example|
                VCR.use_cassette('cdm/digitalindy.org') do
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