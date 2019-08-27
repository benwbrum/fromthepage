require 'spec_helper'

describe "import data" do
    let(:owner){ create(:user, owner: true) }
    before :each do
        DatabaseCleaner.start
        login_as(owner, :scope => :user)
    end
    after :each do
        DatabaseCleaner.clean
    end

    context "CONTENTdm" do

        let(:item_url)      { 'https://cdm16488.contentdm.oclc.org/digital/collection/MPD01/id/2' }
        let(:collection_url){ 'https://cdm16488.contentdm.oclc.org/digital/collection/MPD01' }
        let(:repository_url){ 'https://cdm16488.contentdm.oclc.org/' }

        it "browses a single record" do 
            visit dashboard_owner_path
            click_link("Start A Project")
            VCR.use_cassette('cdm/midpoint-shelwater-item') do
                page.fill_in 'cdm_url', with: item_url
                page.find('#cdm_import').click
            end
            expect(page).to have_content("Manifest: Letter with envelope from Virginia Shewalter")
        end
        it "browses records from a collection" do
            visit dashboard_owner_path
            click_link("Start A Project")
            VCR.use_cassette('cdm/midpoint-shelwater-collection') do
                page.fill_in 'cdm_url', with: collection_url
                page.find('#cdm_import').click
            end
            expect(page).to have_content("Collection: The Virginia Shewalter Letters Collection")
        end
        it "browses collections from a repository" do
            visit dashboard_owner_path
            click_link("Start A Project")
            VCR.use_cassette('cdm/midpoint-repository') do
                page.fill_in 'cdm_url', with: repository_url
                page.find('#cdm_import').click
            end
            expect(page).to have_content("Collections:")
        end
    end
end