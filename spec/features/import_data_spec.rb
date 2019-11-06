require 'spec_helper'

describe "import data" do
  let(:owner){ create(:user, owner: true) }
  before :each do
    DatabaseCleaner.start
  end
  after :each do
    DatabaseCleaner.clean
  end

  context "CONTENTdm" do

    let(:item_url)      { 'https://cdm16488.contentdm.oclc.org/digital/collection/MPD01/id/2' }
    let(:collection_url){ 'https://cdm16488.contentdm.oclc.org/digital/collection/MPD01' }
    let(:repository_url){ 'https://cdm16488.contentdm.oclc.org/' }
    let(:bad_item_url)  { 'https://cdm16488.contentdm.oclc.org/digital/collection/MPD01/id/1' }

    it "browses a single record", :js => true do 
      owner = User.first
      login_as(owner, :scope => :user)
      visit dashboard_owner_path
      page.find('.tabs').click_link("Start A Project")
      page.find(:css, "#import-contentdm").click
      VCR.use_cassette('cdm/midpoint-shelwater-item') do
        page.fill_in 'cdm_url', with: item_url
        page.find('#cdm_import').click
      end
      expect(page).to have_content("Manifest: Letter with envelope from Virginia Shewalter")
    end
    it "browses records from a collection", :js => true do
      owner = User.first
      login_as(owner, :scope => :user)
      visit dashboard_owner_path
      page.find('.tabs').click_link("Start A Project")
      page.find(:css, "#import-contentdm").click
      VCR.use_cassette('cdm/midpoint-shelwater-collection') do
        page.fill_in 'cdm_url', with: collection_url
        page.find('#cdm_import').click
      end
      expect(page).to have_content("Collection: The Virginia Shewalter Letters Collection")
    end
    it "browses collections from a repository", :js => true do
      owner = User.first
      login_as(owner, :scope => :user)
      visit dashboard_owner_path
      page.find('.tabs').click_link("Start A Project")
      page.find(:css, "#import-contentdm").click
      VCR.use_cassette('cdm/midpoint-repository') do
        page.fill_in 'cdm_url', with: repository_url
        page.find('#cdm_import').click
      end
      expect(page).to have_content("Collections:")
    end
    it "Gives an error for a well-formed Cdm URL with a bad/empty IIIF manifest", :js => true do
      owner = User.first
      login_as(owner, :scope => :user)
      visit dashboard_owner_path
      page.find('.tabs').click_link("Start A Project")
      page.find(:css, "#import-contentdm").click
      VCR.use_cassette('cdm/bad_iiif_manifest') do
        page.fill_in 'cdm_url', with: bad_item_url
        page.find('#cdm_import').click
      end
      flash_message = "No IIIF manifest exists for CONTENTdm item #{bad_item_url}"
      expect(page).to have_content(flash_message)
    end
  end
end
