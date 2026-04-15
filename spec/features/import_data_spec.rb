require 'spec_helper'

describe 'import data' do
  let(:owner) { create(:owner) }

  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end

  context 'CONTENTdm' do
    let(:item_url)      { 'https://cdm16488.contentdm.oclc.org/digital/collection/MPD01/id/2' }
    let(:collection_url) { 'https://cdm16488.contentdm.oclc.org/digital/collection/MPD01' }
    let(:repository_url) { 'https://cdm16488.contentdm.oclc.org/' }
    let(:bad_item_url)  { 'https://hrc.contentdm.oclc.org/digital/collection/p15878coll90/id/41/rec/3' }

    it "browses a single record" do
      VCR.use_cassette('cdm/midpoint-shelwater-item', record: :none) do
        owner = User.first
        login_as(owner, scope: :user)
        visit dashboard_owner_path
        page.find('.tabs').click_link("Start A Project")
        find('#cdm_url', visible: false)
          .set(item_url)
        find('#cdm_import', visible: false).click
        expect(page).to have_content('Manifest: Letter with envelope from Virginia Shewalter', wait: 30)
      end
    end

    it 'browses records from a collection' do
      VCR.use_cassette('cdm/midpoint-shelwater-collection', record: :none, allow_playback_repeats: false) do
        owner = User.first
        login_as(owner, scope: :user)
        visit dashboard_owner_path
        page.find('.tabs').click_link('Start A Project')
        find('#cdm_url', visible: false)
          .set(collection_url)
        find('#cdm_import', visible: false).click
        expect(page).to have_content('Collection: The Virginia Shewalter Letters Collection', wait: 30)
      end
    end

    it 'browses collections from a repository' do
      VCR.use_cassette('cdm/midpoint-repository', record: :none) do
        owner = User.first
        login_as(owner, scope: :user)
        visit dashboard_owner_path
        page.find('.tabs').click_link("Start A Project")
        find('#cdm_url', visible: false)
          .set(repository_url)
        find('#cdm_import', visible: false).click
        expect(page).to have_content("Collections:", wait: 10)
      end
    end

    it 'Gives an error for a well-formed Cdm URL with a bad/empty IIIF manifest' do
      VCR.use_cassette('cdm/bad_iiif_manifest', record: :none) do
        owner = User.first
        login_as(owner, scope: :user)
        visit dashboard_owner_path
        page.find('.tabs').click_link('Start A Project')
        find('#cdm_url', visible: false)
          .set(bad_item_url)
        find('#cdm_import', visible: false).click
        flash_message = "No IIIF manifest exists for CONTENTdm item #{bad_item_url}"
        expect(page).to have_content(flash_message, wait: 30)
      end
    end
  end
end
