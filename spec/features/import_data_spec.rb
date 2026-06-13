# frozen_string_literal: true

require 'spec_helper'

describe 'import data' do
  before do
    DatabaseCleaner.start
    login_as(owner, scope: :user)
  end

  after do
    DatabaseCleaner.clean
  end

  let(:owner) { create(:unique_user, :owner, account_type: 'Small Organization') }

  context 'with CONTENTdm' do
    let(:item_url) { 'https://cdm16488.contentdm.oclc.org/digital/collection/MPD01/id/2' }
    let(:collection_url) { 'https://cdm16488.contentdm.oclc.org/digital/collection/MPD01' }
    let(:repository_url) { 'https://cdm16488.contentdm.oclc.org/' }
    let(:bad_item_url) { 'https://hrc.contentdm.oclc.org/digital/collection/p15878coll90/id/41/rec/3' }

    it 'browses a single record' do
      VCR.use_cassette('cdm/midpoint-shelwater-item', record: :none) do
        browse_contentdm(item_url)

        expect(page).to have_content('Manifest: Letter with envelope from Virginia Shewalter', wait: 30)
      end
    end

    it 'browses records from a collection' do
      VCR.use_cassette('cdm/midpoint-shelwater-collection', record: :none, allow_playback_repeats: false) do
        browse_contentdm(collection_url)

        expect(page).to have_content('Collection: The Virginia Shewalter Letters Collection', wait: 30)
      end
    end

    it 'browses collections from a repository' do
      VCR.use_cassette('cdm/midpoint-repository', record: :none) do
        browse_contentdm(repository_url)

        expect(page).to have_content('Collections:', wait: 10)
      end
    end

    it 'gives an error for a well-formed CONTENTdm URL with an empty IIIF manifest' do
      VCR.use_cassette('cdm/bad_iiif_manifest', record: :none) do
        browse_contentdm(bad_item_url)

        expect(page).to have_content("No IIIF manifest exists for CONTENTdm item #{bad_item_url}", wait: 30)
      end
    end
  end

  def browse_contentdm(url)
    visit dashboard_owner_path
    page.find('.tabs').click_link('Start A Project')
    find('#cdm_url', visible: false).set(url)
    find('#cdm_import', visible: false).click
  end
end
